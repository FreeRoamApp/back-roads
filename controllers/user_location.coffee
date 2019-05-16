Promise = require 'bluebird'
geodist = require 'geodist'
_ = require 'lodash'
router = require 'exoid-router'

UserLocation = require '../models/user_location'
EmbedService = require '../services/embed'
PlaceBaseCtrl = require './place_base'

TWO_WEEKS_MS = 3600 * 24 * 7 * 1000

class UserLocationCtrl extends PlaceBaseCtrl
  type: 'userLocation'
  Model: UserLocation
  defaultEmbed: [
    EmbedService.TYPES.USER_LOCATION.USER
    EmbedService.TYPES.USER_LOCATION.PLACE
  ]

  getByMe: ({}, {user}) =>
    UserLocation.getByUserId user.id
    .then EmbedService.embed {embed: @defaultEmbed}

  deleteByMe: ({}, {user}) ->
    UserLocation.getByUserId user.id
    .then (userLocation) ->
      if userLocation
        UserLocation.deleteByRow userLocation

  _getQuery: (location, {distance, outputFn} = {}) =>
    distance ?= 2.5 # TODO: maybe less than 2.5 lat/lon points
    # 2.5 lat lon is ~ 150 mi
    {
      query:
        bool:
          filter: [
            {
              geo_bounding_box:
                location:
                  top_left:
                    lat: location.lat + distance
                    lon: location.lon - distance
                  bottom_right:
                    lat: location.lat - distance
                    lon: location.lon + distance
            }
            {
              match:
                privacy: 'public'
            }
            {
              range:
                'time':
                  gte: new Date(Date.now() - TWO_WEEKS_MS)
            }
          ]
      sort: [
        _geo_distance:
          location:
            lat: location.lat
            lon: location.lon
          order: 'asc'
          unit: 'km'
          distance_type: 'plane'
      ]
    }

  search: ({}, {user}) =>
    @getByMe {}, {user} # FIXME: don't need to embed
    .then (myUserLocation) =>
      unless myUserLocation?.place
        return []
      UserLocation.search @_getQuery(myUserLocation.place.location)
      .then ({total, places}) =>
        Promise.map places, EmbedService.embed {embed: @defaultEmbed}
        .map (place) ->
          distance = geodist myUserLocation.place.location, place.location
          distance = 5 * Math.round(distance / 5) # round to nearest 5
          place = _.defaults {distance}, place
          _.omit place, 'location'
          place.place = _.omit place.place, 'location'
          place
        .then (places) ->
          {total, places}

module.exports = new UserLocationCtrl()
