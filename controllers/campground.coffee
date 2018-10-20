Promise = require 'bluebird'
_ = require 'lodash'

Campground = require '../models/campground'
Amenity = require '../models/amenity'
RoutingService = require '../services/routing'
PlaceBaseCtrl = require './place_base'

COMMON_AMENITIES = ['dump', 'water', 'groceries']

class CampgroundCtrl extends PlaceBaseCtrl
  type: 'campground'
  Model: Campground

  _setNearbyAmenities: (campground) ->
    Amenity.searchNearby campground.location
    .then (amenities) ->
      closestAmenities = _.map COMMON_AMENITIES, (amenityType) ->
        _.find amenities, ({amenities}) ->
          amenities.indexOf(amenityType) isnt -1
      Promise.props _.reduce closestAmenities, (obj, closestAmenity) ->
        if closestAmenity
          obj[closestAmenity.id] = RoutingService.getDistance(
            campground.location, closestAmenity.location
          )
        obj
      , {}
      .then (distances) ->
        _.reduce COMMON_AMENITIES, (obj, amenityType, i) ->
          amenity = closestAmenities[i]
          unless amenity
            return
          distance = distances[amenity.id]
          if amenity and distance
            obj[amenityType] = _.defaults distance, {id: amenity.id}
          obj
        , {}
    .then (distanceTo) ->
      Campground.upsert {
        id: campground.id
        slug: campground.slug
        distanceTo
      }

  upsert: ({id}) =>
    console.log 'upsert', arguments[0]
    super
    .tap (campground) =>
      unless id
        @_setNearbyAmenities campground
      null # don't block

  # TODO: heavily cache this
  getAmenityBoundsById: ({id}) ->
    # get closest dump, water, groceries
    Campground.getById id
    .then (campground) ->
      Amenity.searchNearby campground.location
      .then (amenities) ->
        closestAmenities = _.map COMMON_AMENITIES, (amenityType) ->
          _.find amenities, ({amenities}) ->
            amenities.indexOf(amenityType) isnt -1

        place = {
          location: campground.location
        }
        importantAmenities = _.filter [place].concat closestAmenities
        minX = _.minBy importantAmenities, ({location}) -> location.lon
        minY = _.minBy importantAmenities, ({location}) -> location.lat
        maxX = _.maxBy importantAmenities, ({location}) -> location.lon
        maxY = _.maxBy importantAmenities, ({location}) -> location.lat

        {
          x1: minX.location.lon
          y1: maxY.location.lat
          x2: maxX.location.lon
          y2: minY.location.lat
        }

module.exports = new CampgroundCtrl()
