_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

tables = [
  {
    name: 'user_followers_by_userId_sort_time'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      userId: 'uuid'
      followedId: 'uuid'
    primaryKey:
      partitionKey: ['userId']
      clusteringColumns: ['id', 'followedId']
    withClusteringOrderBy: ['id', 'desc']
  }
  {
    name: 'user_followers_by_followedId_sort_time'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      userId: 'uuid'
      followedId: 'uuid'
    primaryKey:
      partitionKey: ['followedId']
      clusteringColumns: ['id', 'userId']
    withClusteringOrderBy: ['id', 'desc']
  }
  {
    name: 'user_followers_by_userId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      userId: 'uuid'
      followedId: 'uuid'
    primaryKey:
      partitionKey: ['userId']
      clusteringColumns: ['followedId']
  }
  {
    name: 'user_followers_by_followedId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      userId: 'uuid'
      followedId: 'uuid'
    primaryKey:
      partitionKey: ['followedId']
      clusteringColumns: ['userId']
  }
  {
    name: 'user_followers_counter'
    keyspace: 'free_roam'
    fields:
      userId: 'uuid'
      count: 'counter'
    primaryKey:
      partitionKey: ['userId']
  }
  {
    name: 'user_following_counter'
    keyspace: 'free_roam'
    fields:
      userId: 'uuid'
      count: 'counter'
    primaryKey:
      partitionKey: ['userId']
  }
]

defaultUserFollower = (userFollower) ->
  unless userFollower?
    return null

  _.defaults {id: cknex.getTimeUuid()}, userFollower

defaultUserFollowerOutput = (userFollower) ->
  unless userFollower?
    return null

  userFollower.userId = "#{userFollower.userId}"
  userFollower.followedId = "#{userFollower.followedId}"
  userFollower.time = userFollower.id.getDate()

  userFollower

ONE_HOUR_SECONDS = 60

class UserFollowerModel
  SCYLLA_TABLES: tables

  getAllFollowingByUserId: (userId, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'user_followers_by_userId'
      .where 'userId', '=', userId
      .limit 100
      .run()
      .map defaultUserFollowerOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.USER_FOLLOWING}:#{userId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getAllFollowersByUserId: (followedId, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'user_followers_by_followedId'
      .where 'followedId', '=', followedId
      .limit 100
      .run()
      .map defaultUserFollowerOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.USER_FOLLOWERS}:#{followedId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getFollowerCountByUserId: (userId) ->
    cknex().select '*'
    .from 'user_followers_counter'
    .where 'userId', '=', userId
    .run {isSingle: true}

  getFollowingCountByUserId: (userId) ->
    cknex().select '*'
    .from 'user_following_counter'
    .where 'userId', '=', userId
    .run {isSingle: true}

  getByUserIdAndFollowedId: (userId, followedId) ->
    cknex().select '*'
    .from 'user_followers_by_userId'
    .where 'userId', '=', userId
    .andWhere 'followedId', '=', followedId
    .run {isSingle: true}

  create: (userFollower) =>
    userFollower = defaultUserFollower userFollower
    insertObj = {
      id: userFollower.id
      userId: userFollower.userId
      followedId: userFollower.followedId
    }

    Promise.all [
      cknex().insert insertObj
      .into 'user_followers_by_userId_sort_time'
      .run()

      cknex().insert insertObj
      .into 'user_followers_by_followedId_sort_time'
      .run()

      cknex().insert insertObj
      .into 'user_followers_by_userId'
      .run()

      cknex().insert insertObj
      .into 'user_followers_by_followedId'
      .run()

      @incrementCountByUserFollower userFollower, 1
    ]
    .tap ->
      prefix = CacheService.PREFIXES.USER_FOLLOWING
      followedPrefix = CacheService.PREFIXES.USER_FOLLOWERS
      Promise.all [
        CacheService.deleteByKey "#{prefix}:#{userFollower.userId}"
        CacheService.deleteByKey "#{followedPrefix}:#{userFollower.followedId}"
      ]

  incrementCountByUserFollower: (userFollower, amount) ->
    Promise.all [
      cknex().update 'user_followers_counter'
      .increment 'count', amount
      .where 'userId', '=', userFollower.followedId
      .run()

      cknex().update 'user_following_counter'
      .increment 'count', amount
      .where 'userId', '=', userFollower.userId
      .run()
    ]

  deleteByUserFollower: (userFollower) =>
    Promise.all [
      cknex().delete()
      .from 'user_followers_by_userId_sort_time'
      .where 'userId', '=', userFollower.userId
      .andWhere 'followedId', '=', userFollower.followedId
      .andWhere 'id', '=', userFollower.id
      .run()

      cknex().delete()
      .from 'user_followers_by_followedId_sort_time'
      .where 'followedId', '=', userFollower.followedId
      .andWhere 'userId', '=', userFollower.userId
      .andWhere 'id', '=', userFollower.id
      .run()

      cknex().delete()
      .from 'user_followers_by_userId'
      .where 'userId', '=', userFollower.userId
      .andWhere 'followedId', '=', userFollower.followedId
      .run()

      cknex().delete()
      .from 'user_followers_by_followedId'
      .where 'followedId', '=', userFollower.followedId
      .andWhere 'userId', '=', userFollower.userId
      .run()

      @incrementCountByUserFollower userFollower, -1
    ]

  deleteByUserIdAndFollowedId: (userId, followedId) =>
    @getByUserIdAndFollowedId userId, followedId
    .then (userFollower) =>
      if userFollower
        @deleteByUserFollower userFollower
        .tap ->
          prefix = CacheService.PREFIXES.USER_FOLLOWERS
          CacheService.deleteByKey "#{prefix}:#{userId}"

module.exports = new UserFollowerModel()
