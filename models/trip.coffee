_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
request = require 'request-promise'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
elasticsearch = require '../services/elasticsearch'
config = require '../config'

scyllaFields =
  # common between all places
  id: 'timeuuid'
  type: {type: 'text', defaultFn: -> 'custom'} # past, future, custom
  userId: 'uuid'
  name: 'text'
  privacy: {type: 'text', defaultFn: -> 'public'} # public, private, friends
  thumbnailPrefix: 'text'
  imagePrefix: 'text' # screenshot of map
  # 'set's don't appear to work with ordering
  checkInIds: {type: 'list', subType: 'uuid'}
  lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}

class Trip extends Base
  getScyllaTables: ->
    [
      {
        name: 'trips_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['type', 'id']
      }
      {
        name: 'trips_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
    ]

  clearCacheByRow: (row) =>
    userPrefix = CacheService.PREFIXES.TRIPS_GET_ALL_BY_USER_ID
    followingPrefix = CacheService.PREFIXES.TRIPS_GET_ALL_FOLLOWING_BY_USER_ID
    followingCategoryPrefix =
      CacheService.PREFIXES.TRIPS_FOLLOWING_TRIP_ID_CATEGORY

    Promise.all [
      CacheService.deleteByKey "#{userPrefix}:#{row.userId}"
      CacheService.deleteByKey "#{followingPrefix}:#{row.userId}"
      CacheService.deleteByCategory "#{followingCategoryPrefix}:#{row.id}"
    ]

  updateMapByRow: (trip) =>
    imagePrefix = "trips/#{trip.id}_profile"
    Promise.resolve request "#{config.SCREENSHOTTER_HOST}/screenshot",
      json: true
      qs:
        imagePrefix: imagePrefix
        clipY: 32
        viewportHeight: 424
        width: 600
        height: 360
        # TODO: https
        url: "http://#{config.FREE_ROAM_HOST}/travel-map-screenshot/#{trip.id}"
    .then =>
      @upsertByRow trip, {
        imagePrefix
      }

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput

  getById: (id) =>
    cknex().select '*'
    .from @getScyllaTables()[1].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getByUserIdAndType: (userId, type, {createIfNotExists} = {}) =>
    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .andWhere 'type', '=', type
    .limit 1
    .run {isSingle: true}
    .then (trip) =>
      if createIfNotExists and not trip and type in ['past', 'future']
        @upsert {
          type
          userId
          name: _.startCase type
        }
      else
        trip
    .then @defaultOutput

  deleteCheckInIdById: (id, checkInId) =>
    @getById id
    .then (trip) =>
      @upsertByRow trip, {}, {remove: {checkInIds: [checkInId]}}

  defaultInput: (row, options) ->
    row.lastUpdateTime = new Date()
    super row, options

module.exports = new Trip()
