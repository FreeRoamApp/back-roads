Promise = require 'bluebird'
_ = require 'lodash'

Campground = require '../models/campground'
Amenity = require '../models/amenity'
RoutingService = require '../services/routing'
PlaceBaseCtrl = require './place_base'
EmbedService = require '../services/embed'
config = require '../config'

class CampgroundCtrl extends PlaceBaseCtrl
  type: 'campground'
  Model: Campground
  defaultEmbed: [EmbedService.TYPES.CAMPGROUND.ATTACHMENTS_PREVIEW]

  _setNearbyAmenities: (campground) ->
    Amenity.searchNearby campground.location
    .then (amenities) ->
      closestAmenities = _.map config.COMMON_AMENITIES, (amenityType) ->
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
        _.reduce config.COMMON_AMENITIES, (obj, amenityType, i) ->
          amenity = closestAmenities[i]
          unless amenity
            return obj
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

module.exports = new CampgroundCtrl()
