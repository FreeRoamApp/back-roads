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
      .then ([trip, existingCheckIn]) ->
        if existingCheckIn and "#{existingCheckIn.userId}" isnt "#{user.id}"
          router.throw {status: 401, info: 'Unauthorized'}
        else if trip and "#{trip.userId}" isnt "#{user.id}"
          router.throw {status: 401, info: 'Unauthorized'}

        # update if a new trip was added
        isNewTrip = trip and (existingCheckIn?.tripIds or []).indexOf(trip.id) is -1

        if (not isUpdate or isNewTrip) and trip
          diff.tripIds ?= [trip.id]

        CheckIn.upsertByRow existingCheckIn, diff
        .tap (checkIn) ->
          # update if time/location changed
          startTime = new Date(diff.startTime).getTime()
          existingStartTime = existingCheckIn?.startTime?.getTime()
          endTime = new Date(diff.endTime).getTime()
          existingEndTime = existingCheckIn?.endTime?.getTime()
          hasStartTimeChanged =  startTime isnt existingStartTime
          hasEndTimeChanged =  endTime isnt existingEndTime
          hasTimeChanged = hasStartTimeChanged or hasEndTimeChanged

          if (not isUpdate or hasTimeChanged or isNewTrip) and trip
            Trip.upsertDestinationByRoutesEmbeddedTrip(
              trip, checkIn, location, {emit}
            )
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category

module.exports = new CheckInService()
