_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

tables = [
  {
    name: 'user_blocks_by_userId'
    keyspace: 'free_roam'
    fields:
      userId: 'uuid'
      blockedId: 'uuid'
      time: 'timestamp'
    primaryKey:
      partitionKey: ['userId']
      clusteringColumns: ['blockedId']
  }
]

defaultUserBlock = (userBlock) ->
  unless userBlock?
    return null

  _.defaults {time: new Date()}, userBlock

defaultUserBlockOutput = (userBlock) ->
  unless userBlock?
    return null

  userBlock.userId = "#{userBlock.userId}"
  userBlock.blockedId = "#{userBlock.blockedId}"

  userBlock

ONE_HOUR_SECONDS = 60

class UserBlockModel
  SCYLLA_TABLES: tables

  getAllByUserId: (userId, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'user_blocks_by_userId'
      .where 'userId', '=', userId
      .run()
      .map defaultUserBlockOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.USER_BLOCKS}:#{userId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getByUserIdAndBlockedId: (userId, blockedId) ->
    cknex().select '*'
    .from 'user_blocks_by_userId'
    .where 'userId', '=', userId
    .andWhere 'blockedId', '=', blockedId
    .run {isSingle: true}
    .then defaultUserBlockOutput

  upsert: (userBlock) ->
    userBlock = defaultUserBlock userBlock

    cknex().update 'user_blocks_by_userId'
    .set _.omit userBlock, ['userId', 'blockedId']
    .where 'userId', '=', userBlock.userId
    .andWhere 'blockedId', '=', userBlock.blockedId
    .run()
    .tap ->
      prefix = CacheService.PREFIXES.USER_BLOCKS
      CacheService.deleteByKey "#{prefix}:#{userBlock.userId}"

  deleteByUserBlock: (userBlock) ->
    cknex().delete()
    .from 'user_blocks_by_userId'
    .where 'userId', '=', userBlock.userId
    .andWhere 'blockedId', '=', userBlock.blockedId
    .run()

  deleteByUserIdAndBlockedId: (userId, blockedId) =>
    @getByUserIdAndBlockedId userId, blockedId
    .then (userBlock) =>
      if userBlock
        @deleteByUserBlock userBlock
        .tap ->
          prefix = CacheService.PREFIXES.USER_BLOCKS
          CacheService.deleteByKey "#{prefix}:#{userId}"

module.exports = new UserBlockModel()
