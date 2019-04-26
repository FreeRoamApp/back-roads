Promise = require 'bluebird'
geodist = require 'geodist'
_ = require 'lodash'
router = require 'exoid-router'

UserLocation = require '../models/user_location'
EmbedService = require '../services/embed'
PlaceBaseCtrl = require './place_base'

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

  search: ({}, {user}) =>
    @getByMe {}, {user} # FIXME: don't need to embed
    .then (myUserLocation) =>
      console.log myUserLocation.place.location
      UserLocation.searchNearby myUserLocation.place.location
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
