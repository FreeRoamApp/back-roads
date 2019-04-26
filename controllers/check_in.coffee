Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
UserLocation = require '../models/user_location'
CacheService = require '../services/cache'
ImageService = require '../services/image'
PlacesService = require '../services/places'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24

class CheckInCtrl
  defaultEmbed: []

  getById: ({id}, {user}) ->
    CheckIn.getById id

  upsert: (diff, {user}, {emit, socket, route}) ->
    setUserLocation = diff.setUserLocation
    diff = _.pick diff, [
      'id', 'sourceId', 'sourceType', 'name',
      'attachments', 'startTime', 'endTime', 'status', 'tripIds'
    ]

    diff = _.defaults {userId: user.id}, diff

    Promise.all [
      if diff.tripIds?[0]
        Trip.getById diff.tripIds[0]
      else
        type = if diff.status is 'planned' then 'future' else 'past'
        Trip.getByUserIdAndType user.id, type, {createIfNotExists: true}

      if diff.id then CheckIn.getById diff.id else Promise.resolve null

      if setUserLocation
        PlacesService.getByTypeAndId diff.sourceType, diff.sourceId, {
          userId: user.id
        }
        .then ({name, location}) ->
          console.log 'got', name, location
          UserLocation.upsert {
            name: diff.name or name
            userId: user.id
            location: location
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

      unless diff.id
        diff.tripIds ?= [trip.id]

      CheckIn.upsertByRow checkIn, diff, {skipDefaults: false}
      .tap (checkIn) ->
        unless diff.id
          Trip.upsertByRow trip, {}, {add: {checkInIds: [[checkIn.id]]}}
      .tap ->
        Trip.updateMapByRow trip
        .then (trip) ->
          # tell client to reload trip image
          console.log 'emit'
          emit {updatedTrip: trip}
        null # don't block
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category

  getAll: ({includeDetails}, {user}) ->
    includeDetails ?= false
    prefix = CacheService.PREFIXES.CHECK_INS_GET_ALL
    key = "#{prefix}:#{user.id}:#{includeDetails}"
    category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"

    CacheService.preferCache key, ->
      CheckIn.getAllByUserId user.id
      .map (checkIn) ->
        if includeDetails
          PlacesService.getByTypeAndId checkIn.sourceType, checkIn.sourceId, {
            userId: user.id
          }
          .then (place) ->
            _.defaults place, checkIn
        else
          checkIn
    , {category, expireSeconds: ONE_DAY_SECONDS}


  deleteByRow: ({row}, {user}) ->
    CheckIn.getById row.id
    .then (checkIn) ->
      unless checkIn or "#{checkIn?.userId}" is "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}

      Promise.all [
        Promise.map (checkIn.tripIds or []), (tripId) ->
          Trip.deleteCheckInIdById tripId, checkIn.id
        CheckIn.deleteByRow _.defaults({userId: user.id}, checkIn)
      ]
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category


  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'checkin'}
    )

module.exports = new CheckInCtrl()
