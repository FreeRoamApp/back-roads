Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
CacheService = require '../services/cache'
CheckInService = require '../services/check_in'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
PlacesService = require '../services/places'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24

class CheckInCtrl
  defaultEmbed: [EmbedService.TYPES.CHECK_IN.PLACE]

  getById: ({id}, {user}) =>
    CheckIn.getById id
    .then EmbedService.embed {embed: @defaultEmbed}

  upsert: (diff, {user}, {emit}) ->
    CheckInService.upsert diff, user, {emit}

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
          Trip.getById tripId
          .then EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTES]}
          .then (trip) ->
            Trip.deleteDestinationByRoutesEmbeddedTrip trip, checkIn.id
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
