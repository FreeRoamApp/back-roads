_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

ONE_HOUR_SECONDS = 60

###
friends_by_userId
received_requests_by_userId
sent_requests_by_userId

following_by_userId
followed_by_userId

connections_by_userId_and_type_and_type
connection_requests_by_userId_and_type

type: follower
type: followed
type: friend (2x of these, only get created after accepted request)

FIXME: should connection_requests be separate table??? probably same table
connection_requests_by_userId_and_type
type: friendReceived
type: friendSent

###

class ConnectionModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'connections_by_userId_and_type_sort_time'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          type: 'text'
          otherId: 'uuid'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['type', 'id', 'otherId']
        withClusteringOrderBy: [['type', 'desc'], ['id', 'desc']]
      }
      {
        name: 'connections_by_userId_and_type'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          type: 'text'
          otherId: 'uuid'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['type', 'otherId']
      }
      {
        name: 'connections_by_userId_and_type_counter'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          userId: 'uuid'
          type: 'text'
          count: 'counter'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['type']
      }
    ]

  upsert: (connection) =>
    super connection
    .tap ->
      prefix = CacheService.PREFIXES.CONNECTIONS_BY_TYPE
      Promise.all [
        @incrementCountByConnection connection, 1
        CacheService.deleteByKey "#{prefix}:#{connection.userId}"
      ]

  getAllByUserIdAndType: (userId, type, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'connections_by_userId_and_type'
      .where 'userId', '=', userId
      .andWhere 'type', '=', type
      .limit 100
      .run()
      .map @defaultOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.CONNECTIONS_BY_TYPE}:#{userId}:#{type}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getCountByUserIdAndType: (userId, type) ->
    cknex().select '*'
    .from 'connections_by_userId_and_type_counter'
    .where 'userId', '=', userId
    .andWhere 'type', '=', type
    .run {isSingle: true}

  getByUserIdAndOtherIdAndType: (userId, otherId, type) ->
    cknex().select '*'
    .from 'connections_by_userId_and_type'
    .where 'userId', '=', userId
    .andWhere 'type', '=', type
    .andWhere 'otherId', '=', otherId
    .run {isSingle: true}

  incrementCountByConnection: (connection, amount) ->
    Promise.all [
      cknex().update 'connections_by_userId_and_type_counter'
      .increment 'count', amount
      .where 'userId', '=', connection.userId
      .andWhere 'type', '=', connection.type
      .run()

      cknex().update 'connections_by_userId_and_type_counter'
      .increment 'count', amount
      .where 'userId', '=', connection.otherId
      .andWhere 'type', '=', connection.type
      .run()
    ]

  deleteByRow: (row) =>
    super()
    .then =>
      @incrementCountByConnection row, -1

  deleteByUserIdAndOtherIdAndType: (userId, otherId, type) =>
    Promise.all [
      @getByUserIdAndOtherIdAndType userId, otherId, type
      if type is 'friend'
        @getByUserIdAndOtherIdAndType otherId, userId, type
    ]
    .then (connection) =>
      if connection
        @deleteByConnection connection
        .tap ->
          prefix = CacheService.PREFIXES.CONNECTIONS_BY_TYPE
          Promise.all [
            CacheService.deleteByKey "#{prefix}:#{userId}:#{type}"
            if type is 'friend'
              CacheService.deleteByKey "#{prefix}:#{otherId}:#{type}"
          ]

  defaultInput: (connection) ->
    unless connection?
      return null

    _.defaults {id: cknex.getTimeUuid()}, connection

  defaultOutput: (connection) ->
    unless connection?
      return null

    connection.userId = "#{connection.userId}"
    connection.otherId = "#{connection.otherId}"
    connection.time = connection.id.getDate()

    connection

module.exports = new ConnectionModel()
