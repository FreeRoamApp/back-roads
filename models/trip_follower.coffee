_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

ONE_HOUR_SECONDS = 60

scyllaFields =
  id: 'timeuuid'
  userId: 'uuid'
  tripId: 'uuid'

class ConnectionModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'trip_followers_by_tripId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['tripId']
          clusteringColumns: ['id']
        withClusteringOrderBy: [['id', 'desc']]
      }
      {
        name: 'trip_followers_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
        withClusteringOrderBy: [['id', 'desc']]
      }
      {
        name: 'trip_followers_by_userId_and_tripId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['tripId']
      }
      {
        name: 'trip_followers_by_tripId_counter'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          tripId: 'uuid'
          count: 'counter'
        primaryKey:
          partitionKey: ['tripId']
      }
    ]

  upsert: (tripFollower) =>
    super tripFollower
    .tap =>
      userPrefix = CacheService.PREFIXES.TRIP_FOLLOWERS_BY_USER_ID
      tripPrefix = CacheService.PREFIXES.TRIP_FOLLOWERS_BY_TRIP_ID
      Promise.all [
        @incrementCountByTripFollower tripFollower, 1
        CacheService.deleteByKey "#{userPrefix}:#{tripFollower.userId}"
        CacheService.deleteByKey "#{tripPrefix}:#{tripFollower.tripId}"
      ]

  getByUserIdAndTripId: (userId, tripId) ->
    cknex().select '*'
    .from 'trip_followers_by_userId_and_tripId'
    .where 'userId', '=', userId
    .andWhere 'tripId', '=', tripId
    .run {isSingle: true}
    .then @defaultOutput

  getAllByTripId: (tripId, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'trip_followers_by_tripId'
      .where 'tripId', '=', tripId
      .limit 100
      .run()
      .map @defaultOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.TRIP_FOLLOWERS_BY_TRIP_ID}:#{userId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getAllByUserId: (userId, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'trip_followers_by_userId'
      .where 'userId', '=', userId
      .limit 100
      .run()
      .map @defaultOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.TRIP_FOLLOWERS_BY_USER_ID}:#{userId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getCountByTripid: (tripId) ->
    cknex().select '*'
    .from 'trip_followers_by_tripId_counter'
    .where 'tripId', '=', tripId
    .run {isSingle: true}

  incrementCountByTripFollower: (tripFollower, amount) ->
    cknex().update 'trip_followers_by_tripId_counter'
    .increment 'count', amount
    .where 'tripId', '=', tripFollower.tripId
    .run()

  deleteByRow: (row) =>
    super row
    .then =>
      @incrementCountByTripFollower row, -1
    .then =>
      userPrefix = CacheService.PREFIXES.TRIP_FOLLOWERS_BY_USER_ID
      tripPrefix = CacheService.PREFIXES.TRIP_FOLLOWERS_BY_TRIP_ID
      CacheService.deleteByKey "#{userPrefix}:#{row.userId}"
      CacheService.deleteByKey "#{tripPrefix}:#{row.tripId}"

  defaultOutput: (tripFollower) ->
    unless tripFollower
      return null
    tripFollower.time = cknex.getDateFromTimeUuid tripFollower.id
    tripFollower = super tripFollower


module.exports = new ConnectionModel()
