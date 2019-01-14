Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
Amenity = require '../models/amenity'
Campground = require '../models/campground'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
CacheService = require '../services/cache'
ImageService = require '../services/image'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24

class CheckInCtrl
  defaultEmbed: []

  getById: ({id}, {user}) ->
    CheckIn.getById id

  # TODO: create past/future trip if it doesn't exist, and add check-in to trip
  # TODO: replace trip.addCheckIn with this? accept tripType, tripId
  upsert: (diff, {user}) ->
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
    ]
    .then ([trip, checkIn]) ->
      if checkIn and "#{checkIn.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}
      else if trip and "#{trip.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}

      unless diff.id
        diff.tripIds ?= [trip.id]

      CheckIn.upsertByRow checkIn, diff
      .tap (checkIn) ->
        unless diff.id
          Trip.upsertByRow trip, {}, {add: {checkInIds: [[checkIn.id]]}}
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
          (if checkIn.sourceType is 'amenity'
            Amenity.getById checkIn.sourceId
          else if checkIn.sourceType is 'overnight'
            Overnight.getById checkIn.sourceId
          else if checkIn.sourceType is 'coordinate'
            Coordinate.getByUserIdAndId user.id, checkIn.sourceId
          else
            Campground.getById checkIn.sourceId
          ).then (place) ->
            _.defaults place, checkIn
        else
          checkIn
    , {category, expireSeconds: ONE_DAY_SECONDS}


  deleteByRow: ({row}, {user}) ->
    CheckIn.getById row.id
    .then (checkIn) ->
      unless checkIn or "#{checkIn.userId}" is "#{user.id}"
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
