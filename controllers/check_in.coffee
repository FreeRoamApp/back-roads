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
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24

class CheckInCtrl
  defaultEmbed: []

  getById: ({id}, {user}) ->
    CheckIn.getById id

  upsert: ({sourceId, sourceType}, {user}) ->
    CheckIn.upsert {
      sourceId, sourceType
      userId: user.id
    }
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
      Promise.all [
        Promise.map checkIn.tripIds, (tripId) ->
          Trip.deleteCheckInIdById tripId, checkIn.id
        CheckIn.deleteByRow _.defaults({userId: user.id}, checkIn)
      ]
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category


module.exports = new CheckInCtrl()
