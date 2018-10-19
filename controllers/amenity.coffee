geodist = require 'geodist'
Promise = require 'bluebird'
_ = require 'lodash'

Amenity = require '../models/amenity'
Campground = require '../models/campground'
PlaceBaseCtrl = require './place_base'
GeocoderService = require '../services/geocoder'
RoutingService = require '../services/routing'
config = require '../config'

class AmenityCtrl extends PlaceBaseCtrl
  type: 'amenity'
  Model: Amenity

  _updateNearbyCampgrounds: (amenity) ->
    Campground.searchNearby amenity.location, {
      outputFn: (campground) -> campground
    }
    .then (campgrounds) ->
      campgroundsIsClosestAmenity = _.filter campgrounds, (campground) ->
        _.some _.map amenity.amenities, (amenityType) ->
          distance = geodist amenity.location, campground.location
          if campground.distanceTo?[amenityType]?.distance < distance
            return
          campground

      Promise.map campgroundsIsClosestAmenity, (campground) ->
        RoutingService.getDistance amenity.location, campground.location
        .then (distance) ->
          {campground, distance}
      .filter ({campground, distance}) ->
        _.some _.map amenity.amenities, (amenityType) ->
          campground.distanceTo?[amenityType]?.time >= distance.time
    .then (campgrounds) ->
      Promise.map campgrounds, ({campground, distance}) ->
        oldDistanceTo = campground.distanceTo or {}
        newDistanceTo = _.reduce amenity.amenities, (obj, amenityType) ->
          if not oldDistanceTo[amenityType]? or oldDistanceTo[amenityType].time >= distance.time
            obj[amenityType] = _.defaults distance, {id: amenity.id}
          obj
        , oldDistanceTo

        console.log 'upsert', {
          id: campground.id
          slug: campground.slug
          distanceTo: newDistanceTo
        }

        Campground.upsert {
          id: campground.id
          slug: campground.slug
          distanceTo: newDistanceTo
        }


  upsert: (options, {user, headers, connection}) =>
    {id, name, location, slug, amenities, prices} = options

    matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec location
    unless matches?[0] and matches?[1]
      console.log 'invalid', location
      router.throw {info: 'invalid location', status: 400}
    location = {
      lat: parseFloat(matches[1])
      lon: parseFloat(matches[2])
    }

    Promise.all [
      (if slug
        Promise.resolve slug
      else
        slug = _.kebabCase(name)
        @getUniqueSlug slug)

      GeocoderService.reverse location
      .catch -> null
    ]
    .then ([slug, address]) =>
      address =
        locality: address?[0]?.city
        administrativeArea: address?[0]?.state

      @Model.upsert {slug, name, location, address, amenities, prices}
    .tap (amenity) =>
      unless id
        @_updateNearbyCampgrounds amenity
      null # don't block


module.exports = new AmenityCtrl()
