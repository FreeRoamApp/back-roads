Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
TripFollower = require '../models/trip_follower'
CacheService = require '../services/cache'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
statesGeoJson = require '../resources/data/states.json'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.TRIP.CHECK_INS
  EmbedService.TYPES.TRIP.USER
]
extrasEmbed = [
  EmbedService.TYPES.TRIP.ROUTE
]
overviewEmbed = [
  # TODO: consolidate stats, overview
  EmbedService.TYPES.TRIP.STATS
  EmbedService.TYPES.TRIP.OVERVIEW
]

ONE_DAY_SECONDS = 3600 * 24

class TripCtrl
  upsert: (diff, {user, file}) =>
    diff = _.pick diff, [
      'checkInIds', 'id', 'imagePrefix', 'privacy', 'name', 'type',
      'thumbnailPrefix'
    ]
    diff = _.defaults {userId: user.id}, diff
    (if diff.id
      Trip.getById diff.id
    else
      Promise.resolve null
    )
    .then (trip) =>
      if trip and "#{trip.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}

      Trip.upsertByRow trip, diff
      .then (trip) =>
        if file
          console.log 'uploading file'
          @_uploadThumbnail trip.id, file
          .then (thumbnail) ->
            Trip.upsertByRow trip, {
              thumbnailPrefix: thumbnail.prefix
            }
        else
          trip

  _uploadThumbnail: (tripId, file) ->
    ImageService.uploadImageByUserIdAndFile(
      tripId, file, {folder: 'trips'}
    )

  deleteByRow: ({row}, {user}) ->
    Trip.getById row.id
    .then (trip) ->
      unless trip.userId is user.id
        router.throw {status: 401, info: 'Unauthorized'}
      unless trip.type is 'custom'
        router.throw {status: 400, info: 'Can only delete custom trips'}

      Trip.deleteByRow trip

  getAll: ({}, {user}) ->
    prefix = CacheService.PREFIXES.TRIPS_GET_ALL_BY_USER_ID
    key = "#{prefix}:#{user.id}"
    CacheService.preferCache key, ->
      Trip.getAllByUserId user.id
      .map EmbedService.embed {embed: defaultEmbed}
      .map EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTE]}
      .map EmbedService.embed {embed: overviewEmbed}
      .map (trip) -> _.omit trip, ['checkIns', 'route']
    , {expireSeconds: ONE_DAY_SECONDS}
    .then (trips) ->
      # add in past / future type trips if they don't exist yet
      trips.concat _.filter [
        unless _.find trips, {type: 'past'}
          {
            type: 'past'
            userId: user.id
            name: 'Past'
            overview:
              stops: 0
              distance: 0
          }
        unless _.find trips, {type: 'future'}
          {
            type: 'future'
            userId: user.id
            name: 'Future'
            overview:
              stops: 0
              distance: 0
          }
      ]

  getAllFollowingByUserId: ({userId}, {user}) ->
    # TODO: clear whenever trip is updated
    prefix = CacheService.PREFIXES.TRIPS_GET_ALL_FOLLOWING_BY_USER_ID
    key = "#{prefix}:#{user.id}"

    CacheService.preferCache key, ->
      TripFollower.getAllByUserId userId
      .map EmbedService.embed {embed: [EmbedService.TYPES.TRIP_FOLLOWER.TRIP]}
      .map (tripFollower) ->
        if tripFollower.trip
          prefix = CacheService.PREFIXES.TRIPS_FOLLOWING_TRIP_ID_CATEGORY
          category = "#{prefix}:#{tripFollower.trip.id}"
          CacheService.addCacheKeyToCategory key, category

        tripFollower.trip
      .then (trips) -> _.filter trips
      .map EmbedService.embed {embed: defaultEmbed}
      .map EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTE]}
      .map EmbedService.embed {embed: overviewEmbed}
      .map (trip) -> _.omit trip, ['checkIns', 'route']
    , {expireSeconds: ONE_DAY_SECONDS}

  getById: ({id}, {user}) ->
    # HACK: not sure where, but this is caled with 'null' when tooltip is opened
    # when adding new checkin
    if id is 'null'
      return null
    Trip.getById id
    .tap (trip) ->
      if trip?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'
    .then EmbedService.embed {embed: defaultEmbed}
    .then EmbedService.embed {embed: extrasEmbed}
    .then EmbedService.embed {embed: overviewEmbed}

  getByType: ({type}, {user}) ->
    Trip.getByUserIdAndType user.id, type, {createIfNotExists: true}
    .then EmbedService.embed {embed: defaultEmbed, options: {userId: user.id}}
    .then EmbedService.embed {embed: extrasEmbed}
    .then EmbedService.embed {embed: overviewEmbed}

  getByUserIdAndType: ({userId, type}, {user}) ->
    Trip.getByUserIdAndType userId, type
    .tap (trip) ->
      if trip?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'
    .then EmbedService.embed {embed: defaultEmbed, options: {userId}}
    # .then EmbedService.embed {embed: extrasEmbed}

  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'trips'}
    )

  getStatesGeoJson: ->
    statesGeoJson

module.exports = new TripCtrl()
