_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

ONE_HOUR_SECONDS = 60

class UserBlockModel extends Base
  getScyllaTables: ->
    [
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

  upsert: (userBlock) =>
    super userBlock
    .tap ->
      prefix = CacheService.PREFIXES.USER_BLOCKS
      CacheService.deleteByKey "#{prefix}:#{userBlock.userId}"

  getAllByUserId: (userId, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'user_blocks_by_userId'
      .where 'userId', '=', userId
      .run()
      .map @defaultOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.USER_BLOCKS}:#{userId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getByUserIdAndBlockedId: (userId, blockedId) =>
    cknex().select '*'
    .from 'user_blocks_by_userId'
    .where 'userId', '=', userId
    .andWhere 'blockedId', '=', blockedId
    .run {isSingle: true}
    .then @defaultOutput

  # TODO: super() (deleteByRow)
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

  defaultInput: (userBlock) ->
    unless userBlock?
      return null

    _.defaults {time: new Date()}, userBlock

  defaultOutput : (userBlock) ->
    unless userBlock?
      return null

    userBlock.userId = "#{userBlock.userId}"
    userBlock.blockedId = "#{userBlock.blockedId}"

    userBlock

module.exports = new UserBlockModel()
