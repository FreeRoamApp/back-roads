_ = require 'lodash'
Promise = require 'bluebird'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
UserLocation = require '../models/user_location'
UserSettings = require '../models/user_settings'
PlacesService = require './places'
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

    Promise.all [
      if diff.tripIds?[0]
        Trip.getById diff.tripIds[0]
      else
        type = if diff.status is 'planned' then 'future' else 'past'
        Trip.getByUserIdAndType user.id, type, {createIfNotExists: true}

      if isUpdate then CheckIn.getById diff.id else Promise.resolve null

      if setUserLocation
        UserSettings.getByUserId user.id
        .then (userSettings) ->
          PlacesService.getByTypeAndId diff.sourceType, diff.sourceId, {
            userId: user.id
          }
          .then ({name, location}) ->
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
      if checkIn and "#{checkIn.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}
      else if trip and "#{trip.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}

      unless isUpdate
        diff.tripIds ?= [trip.id]

      CheckIn.upsertByRow checkIn, diff
      .tap (checkIn) ->
        unless isUpdate
          Trip.upsertByRow trip, {}, {add: {checkInIds: [[checkIn.id]]}}
      .tap ->
        Trip.updateMapByRow trip
        .then (trip) ->
          # tell client to reload trip image
          emit? {updatedTrip: trip}
        null # don't block
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category

module.exports = new CheckInService()
