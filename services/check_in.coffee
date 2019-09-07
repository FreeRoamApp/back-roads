_ = require 'lodash'
Promise = require 'bluebird'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
UserLocation = require '../models/user_location'
UserSettings = require '../models/user_settings'
PlacesService = require './places'
EmbedService = require './embed'
CacheService = require './cache'

class CheckInService
  upsert: (diff, user, {emit} = {}) ->
    setUserLocation = diff.setUserLocation
    diff = _.pick diff, [
      'id', 'sourceId', 'sourceType', 'name', 'notes'
      'attachments', 'startTime', 'endTime', 'status', 'tripIds'
    ]

    isUpdate = Boolean diff.id

    diff = _.defaults {userId: user.id}, diff

    console.log diff
    PlacesService.getByTypeAndId diff.sourceType, diff.sourceId, {
      userId: user.id
    }
    .then ({name, location}) ->
      Promise.all [
        if diff.tripIds?[0]
          Trip.getById diff.tripIds[0]
          .then EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTES]}
        else
          Promise.resolve null

        if isUpdate then CheckIn.getById diff.id else Promise.resolve null

        if setUserLocation
          UserSettings.getByUserId user.id
          .then (userSettings) ->
            UserLocation.upsert {
              name: diff.name or name
              userId: user.id
              location: location
              privacy: if userSettings?.privacy?.location?.everyone \
                       then 'public'
                       else 'private'
              sourceType: diff.sourceType
              sourceId: diff.sourceId
            }
        else
          Promise.resolve null
      ]
      .then ([trip, checkIn]) ->
        console.log 'trip', trip
        if checkIn and "#{checkIn.userId}" isnt "#{user.id}"
          router.throw {status: 401, info: 'Unauthorized'}
        else if trip and "#{trip.userId}" isnt "#{user.id}"
          router.throw {status: 401, info: 'Unauthorized'}

        if not isUpdate and trip
          diff.tripIds ?= [trip.id]

        CheckIn.upsertByRow checkIn, diff
        .tap (checkIn) ->
          if not isUpdate and trip
            Trip.upsertDestinationByRoutesEmbeddedTrip trip, checkIn, location
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category

module.exports = new CheckInService()
