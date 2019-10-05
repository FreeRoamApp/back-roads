Redlock = require 'redlock'
Promise = require 'bluebird'

RedisService = require './redis'
RedisPersistentService = require './redis_persistent'
PubSub = require './pub_sub'
config = require '../config'

DEFAULT_CACHE_EXPIRE_SECONDS = 3600 * 24 * 30 # 30 days
DEFAULT_LOCK_EXPIRE_SECONDS = 3600 * 24 * 40000 # 100+ years
ONE_HOUR_SECONDS = 3600
ONE_MINUTE_SECONDS = 60
PREFER_CACHE_PUB_SUB_TIMEOUT_MS = 30 * 1000


class CacheService
  KEYS:
    STALE_THREAD_IDS: 'threads:stale_ids'
    DAILY_UPDATE_ID: 'dailyUpdate:id4'
  LOCK_PREFIXES: {}
  LOCKS:
    DAILY_UPDATE: 'dailyUpdate5'
  PREFIXES:
    CHAT_USER: 'chat:user3'
    CHAT_USER_BY_USERNAME: 'chat:user:byUsername3'
    CHAT_GROUP_USER: 'chat:group_user'
    CHAT_MESSAGE_DAILY_XP: 'chat_message:daily_xp'
    CHECK_INS_GET_ALL: 'check_ins:getAll0'
    CHECK_INS_GET_ALL_CATEGORY: 'check_ins:getAll:category'
    COMMENTS_BY_TOP_ID: 'comments:topId'
    COMMENTS_BY_TOP_ID_CATEGORY: 'comments:topId:category'
    COMMENTS: 'thread:comments18'
    COMMENT_COUNT: 'thread:commentCount'
    CONNECTIONS_BY_USER: 'connections:user'
    CONNECTIONS_BY_TYPE: 'connections:type'
    CONVERSATION_ID: 'conversation:id7'
    GROUP_ID: 'group:id'
    GROUP_SLUG: 'group:slug'
    GROUP_GET_ALL: 'group:getAll2'
    GROUP_GET_ALL_CATEGORY: 'group:getAll:category2'
    GROUP_USER_COUNT: 'group:user_count2'
    GROUP_ROLE_GROUP_ID_USER_ID: 'group_role:groupId:userId4'
    GROUP_ROLES: 'group_role:groupId2'
    GROUP_USER_USER_ID: 'group_user:user_id10'
    GROUP_USER_TOP: 'group_user:top3'
    GROUP_USERS_ONLINE: 'group_users:online2'
    HONEY_POT_BAN_IP: 'honey_pot:ban_ip'
    PLACE_BEST_BOUNDING: 'place:best_bounding3'
    PUBLIC_CHANNELS_BY_GROUP_ID: 'conversation:public_by_groupId'
    ROUTING_ROUTE: 'routing:route3'
    ROUTE_STOP_INDEX: 'route:stop_index'
    THREAD: 'thread:id:embedded3'
    THREAD_BY_SLUG: 'thread:slug3'
    THREAD_BY_ID: 'thread:id'
    THREAD_WITH_EMBEDS_BY_ID: 'thread:with_embeds:id'
    THREAD_WITH_EMBEDS_BY_SLUG: 'thread:with_embeds:slug3'
    THREADS_BY_CATEGORY: 'threads:by_category'
    THREADS_CATEGORY: 'threads:category'
    TRIP_FOLLOWERS_BY_TRIP_ID: 'trip_followers:tripId'
    TRIP_FOLLOWERS_BY_USER_ID: 'trip_followers:userId'
    TRIPS_GET_ALL_BY_USER_ID: 'trips:getAll:userId2'
    TRIPS_GET_ALL_FOLLOWING_BY_USER_ID: 'trips:getAllFollowing:userId1'
    TRIPS_FOLLOWING_TRIP_ID_CATEGORY: 'trips:following:tripId:category'
    COMMENT_COUNT: 'thread:comment_count1'
    THREAD_CREATOR: 'thread:creator'
    THREAD_USER: 'thread:user'
    USER_ID: 'user:id'
    USER_BLOCKS: 'user_blocks:all'
  STATIC:
    KARMA_LEADERBOARD: 'karma_leaderboard'
  STATIC_PREFIXES: # anything that's persistent (leaderboards, etc...)
    # these should stay, don't add a number to end to clear
    THREAD_KARMA_LEADERBOARD_BY_CATEGORY: 'thread:group_leaderboard:by_category'
    THREAD_KARMA_LEADERBOARD_ALL: 'thread:group_leaderboard:by_all'

  constructor: ->
    @redlock = new Redlock [RedisService], {
      driftFactor: 0.01
      retryCount: 0
      # retryDelay:  200
    }

  tempSetAdd: (key, value) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisService.sadd key, value

  tempSetGetAll: (key) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisService.smembers key

  setAdd: (key, value) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisPersistentService.sadd key, value

  setRemove: (key, value) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisPersistentService.srem key, value

  setGetAll: (key) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisPersistentService.smembers key

  leaderboardUpdate: (setKey, member, score) ->
    key = config.REDIS.PREFIX + ':' + setKey
    RedisPersistentService.zadd key, score, member

  leaderboardDelete: (setKey, member) ->
    key = config.REDIS.PREFIX + ':' + setKey
    RedisPersistentService.zrem key, member

  leaderboardIncrement: (setKey, member, increment, {currentValueFn} = {}) =>
    key = config.REDIS.PREFIX + ':' + setKey
    RedisPersistentService.zincrby key, increment, member
    .tap (newValue) =>
      # didn't exist before, sync their xp just in case
      if currentValueFn and "#{newValue}" is "#{increment}"
        currentValueFn()
        .then (currentValue) =>
          if currentValue and "#{currentValue}" isnt "#{newValue}"
            @leaderboardUpdate setKey, member, currentValue
        null # don't block

  leaderboardGet: (key, {limit, skip} = {}) ->
    skip ?= 0
    limit ?= 50
    key = config.REDIS.PREFIX + ':' + key
    RedisPersistentService.zrevrange key, skip, skip + limit - 1, 'WITHSCORES'

  leaderboardTrim: (key, trimLength = 10000) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisPersistentService.zremrangebyrank key, 0, -1 * (trimLength + 1)

  set: (key, value, {expireSeconds} = {}) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisService.set key, JSON.stringify value
    .then ->
      if expireSeconds
        RedisService.expire key, expireSeconds

  get: (key) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisService.get key
    .then (value) ->
      try
        JSON.parse value
      catch err
        value

  getCursor: (cursor) =>
    key = "#{PREFIXES.CURSOR}:#{cursor}"
    @get key

  setCursor: (cursor, value) =>
    key = "#{PREFIXES.CURSOR}:#{cursor}"
    @set key, value, {expireSeconds: ONE_HOUR_SECONDS}

  lock: (key, fn, {expireSeconds, unlockWhenCompleted, throwOnLocked} = {}) =>
    key = config.REDIS.PREFIX + ':' + key
    expireSeconds ?= DEFAULT_LOCK_EXPIRE_SECONDS
    @redlock.lock key, expireSeconds * 1000
    .then (lock) ->
      fnResult = fn(lock)
      if not fnResult?.then
        return fnResult
      else
        fnResult.then (result) ->
          if unlockWhenCompleted
            lock.unlock()
          result
        .catch (err) ->
          lock.unlock()
          throw {fnError: err}
    .catch (err) ->
      if err.fnError
        throw err.fnError
      else if throwOnLocked
        throw {isLocked: true}
      # don't pass back other (redlock) errors

  addCacheKeyToCategory: (key, category) =>
    categoryKey = 'category:' + category
    @tempSetAdd categoryKey, key

  # run fn that returns promise and cache result
  # if many request before result is ready, then all subscribe/wait for result
  # if we want to reduce load / network on pubsub, we could have it be
  # an option to use pubsub
  preferCache: (key, fn, {expireSeconds, ignoreNull, category} = {}) =>
    unless key
      console.log 'missing cache key'
    rawKey = key
    key = config.REDIS.PREFIX + ':' + key
    expireSeconds ?= DEFAULT_CACHE_EXPIRE_SECONDS

    if category
      @addCacheKeyToCategory rawKey, category

    RedisService.get key
    .then (value) =>
      if value?
        try
          return JSON.parse value
        catch err
          console.log 'error parsing', key, value
          return null

      pubSubChannel = "#{key}:pubsub"

      @lock "#{key}:run_lock", ->
        try
          fn().then (value) ->
            unless rawKey
              console.log 'missing cache key value', value
            if (value isnt null and value isnt undefined) or not ignoreNull
              RedisService.set key, JSON.stringify value
              .then ->
                RedisService.expire key, expireSeconds
            setTimeout ->
              PubSub.publish [pubSubChannel], value
            , 100 # account for however long it takes for other instances to acquire / check lock / subscribe
            return value
        catch err
          console.log err
          throw err
      , {
        unlockWhenCompleted: true, expireSeconds: ONE_MINUTE_SECONDS
        throwOnLocked: true
      }
      .catch (err) ->
        if err?.isLocked
          new Promise (resolve) ->
            subscription = PubSub.subscribe pubSubChannel, (value) ->
              subscription?.unsubscribe?()
              clearTimeout unsubscribeTimeout
              resolve value
            unsubscribeTimeout = setTimeout ->
              subscription?.unsubscribe?()
            , PREFER_CACHE_PUB_SUB_TIMEOUT_MS

        else
          throw err

  deleteByCategory: (category) =>
    categoryKey = 'category:' + category
    @tempSetGetAll categoryKey
    .then (categoryKeys) =>
      Promise.map categoryKeys, @deleteByKey
    .then =>
      @deleteByKey categoryKey

  deleteByKey: (key) ->
    key = config.REDIS.PREFIX + ':' + key
    RedisService.del key

module.exports = new CacheService()
