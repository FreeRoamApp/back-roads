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
          clusteringColumns: ['type', 'id']
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
    if connection.type in ['friend', 'friendRequestSent']
      otherConnection = _.defaults {
        userId: "#{connection.otherId}"
        otherId: "#{connection.userId}"
        type: if connection.type is 'friendRequestSent' \
              then 'friendRequestReceived'
              else connection.type
      }, connection

    Promise.all _.filter [
      super connection
      if otherConnection?
        super otherConnection
    ]
    .tap =>
      prefix = CacheService.PREFIXES.CONNECTIONS_BY_USER
      typePrefix = CacheService.PREFIXES.CONNECTIONS_BY_TYPE
      Promise.all [
        @incrementCountByConnection connection, 1
        CacheService.deleteByKey "#{prefix}:#{connection.userId}"
        CacheService.deleteByKey "#{typePrefix}:#{connection.userId}:#{connection.type}"
        if otherConnection
          @incrementCountByConnection otherConnection, 1
          CacheService.deleteByKey "#{prefix}:#{otherConnection.otherId}"
          CacheService.deleteByKey "#{typePrefix}:#{otherConnection.otherId}:#{otherConnection.otherType}"
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

  getAllByUserId: (userId, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'connections_by_userId_and_type'
      .where 'userId', '=', userId
      .limit 100
      .run()
      .map @defaultOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.CONNECTIONS_BY_USER}:#{userId}"
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
    super row
    .then =>
      @incrementCountByConnection row, -1

  deleteByUserIdAndOtherIdAndType: (userId, otherId, type) =>
    otherType = null
    Promise.all _.filter [
      @getByUserIdAndOtherIdAndType userId, otherId, type
      if type in ['friend', 'friendRequestSent', 'friendRequestReceived']
        if type is 'friendRequestSent'
          otherType = 'friendRequestReceived'
        else if type is 'friendRequestReceived'
          otherType = 'friendRequestSent'
        else
          otherType = type
        @getByUserIdAndOtherIdAndType otherId, userId, otherType
    ]
    .map (connection) =>
      if connection
        console.log 'delete', connection
        @deleteByRow connection
        .tap ->
          prefix = CacheService.PREFIXES.CONNECTIONS_BY_USER
          typePrefix = CacheService.PREFIXES.CONNECTIONS_BY_TYPE
          Promise.all [
            CacheService.deleteByKey "#{prefix}:#{userId}"
            CacheService.deleteByKey "#{typePrefix}:#{userId}:#{type}"
            if otherType
              CacheService.deleteByKey "#{prefix}:#{otherId}"
              CacheService.deleteByKey "#{typePrefix}:#{otherId}:#{otherType}"
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
