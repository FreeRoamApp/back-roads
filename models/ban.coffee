_ = require 'lodash'

uuid = require 'node-uuid'

CacheService = require '../services/cache'
cknex = require '../services/cknex'
config = require '../config'

honeypot = require('project-honeypot')(config.HONEYPOT_ACCESS_KEY)

defaultBan = (ban) ->
  unless ban?
    return null

  _.defaults ban, {
    ip: ''
    id: cknex.getTimeUuid()
  }

ONE_DAY_SECONDS = 3600 * 24
ONE_MONTH_SECONDS = 3600 * 24 * 31

tables = [
  {
    name: 'bans_by_userId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      groupId: 'uuid'
      userId: 'uuid'
      bannedById: 'uuid'
      duration: 'text'
      ip: 'text'
    primaryKey:
      partitionKey: ['groupId']
      clusteringColumns: ['userId']
  }
  {
    name: 'bans_by_ip'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      groupId: 'uuid'
      userId: 'uuid'
      bannedById: 'uuid'
      duration: 'text'
      ip: 'text'
    primaryKey:
      partitionKey: ['groupId']
      clusteringColumns: ['ip']
  }
  {
    name: 'bans_by_duration_and_id'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      groupId: 'uuid'
      userId: 'uuid'
      bannedById: 'uuid'
      duration: 'text'
      ip: 'text'
    primaryKey:
      partitionKey: ['groupId', 'duration']
      clusteringColumns: ['id']
    withClusteringOrderBy: ['id', 'desc']
  }
]

class BanModel
  SCYLLA_TABLES: tables

  upsert: (ban, {ttl} = {}) ->
    ban = defaultBan ban

    queries = [
      cknex().update 'bans_by_userId'
      .set _.omit ban, [
        'groupId', 'userId'
      ]
      .where 'groupId', '=', ban.groupId
      .andWhere 'userId', '=', ban.userId

      cknex().update 'bans_by_ip'
      .set _.omit ban, [
        'groupId', 'ip'
      ]
      .where 'groupId', '=', ban.groupId
      .andWhere 'ip', '=', ban.ip

      cknex().update 'bans_by_duration_and_id'
      .set _.omit ban, [
        'groupId', 'duration', 'id'
      ]
      .where 'groupId', '=', ban.groupId
      .andWhere 'duration', '=', ban.duration
      .andWhere 'id', '=', ban.id
    ]

    if ttl
      queries = _.map queries, (query) ->
        query.usingTTL ttl

    Promise.all _.map queries, (query) ->
      query.run()
    .then ->
      if ban.userId
        prefix = CacheService.PREFIXES.BAN_USER_ID
        key = "#{prefix}:#{ban.groupId}:#{ban.userId}"
        CacheService.deleteByKey key
      if ban.ip
        prefix = CacheService.PREFIXES.BAN_IP
        key = "#{prefix}:#{ban.groupId}:#{ban.ip}"
        CacheService.deleteByKey key
      ban

  isHoneypotBanned: (ip, {preferCache} = {}) ->
    get = ->
      if ip?.match('74.82.60')
        return Promise.resolve true
      new Promise (resolve, reject) ->
        honeypot.query ip, (err, payload) ->
          console.log ip, payload
          if err
            resolve false
          else
            isBanned = payload?.type?.spammer
            resolve isBanned

    if preferCache
      key = "#{CacheService.PREFIXES.HONEY_POT_BAN_IP}:#{ip}"
      CacheService.preferCache key, get, {expireSeconds: ONE_MONTH_SECONDS}
    else
      get()

  getAllByGroupIdAndDuration: (groupId, duration) ->
    cknex().select '*'
    .from 'bans_by_duration_and_id'
    .where 'groupId', '=', groupId
    .andWhere 'duration', '=', duration
    .limit 100
    .run()
    .map defaultBan

  getByGroupIdAndIp: (groupId, ip, {scope, preferCache} = {}) ->
    scope ?= 'chat'

    get = ->
      cknex().select '*'
      .from 'bans_by_ip'
      .where 'groupId', '=', groupId
      .andWhere 'ip', '=', ip
      .run {isSingle: true}
      .then defaultBan

    if preferCache
      key = "#{CacheService.PREFIXES.BAN_IP}:#{groupId}:#{ip}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_SECONDS}
    else
      get()

  getByGroupIdAndUserId: (groupId, userId, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'bans_by_userId'
      .where 'groupId', '=', groupId
      .andWhere 'userId', '=', userId
      .run {isSingle: true}
      .then defaultBan

    if preferCache
      key = "#{CacheService.PREFIXES.BAN_USER_ID}:#{groupId}:#{userId}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_SECONDS}
    else
      get()

  deleteByBan: (ban) ->
    Promise.all _.filter [
      cknex().delete()
      .from 'bans_by_userId'
      .where 'groupId', '=', ban.groupId
      .andWhere 'userId', '=', ban.userId
      .run()

      if ban.ip
        cknex().delete()
        .from 'bans_by_ip'
        .where 'groupId', '=', ban.groupId
        .andWhere 'ip', '=', ban.ip
        .run()

      cknex().delete()
      .from 'bans_by_duration_and_id'
      .where 'groupId', '=', ban.groupId
      .andWhere 'duration', '=', ban.duration
      .andWhere 'id', '=', ban.id
      .run()
    ]

  deleteAllByGroupIdAndIp: (groupId, ip) =>
    cknex().select '*'
    .from 'bans_by_userId'
    .where 'groupId', '=', groupId
    .andWhere 'ip', '=', ip
    .run()
    .map @deleteByBan
    .then ->
      key = "#{CacheService.PREFIXES.BAN_IP}:#{groupId}:#{ip}"
      CacheService.deleteByKey key
    .then -> null

  deleteAllByGroupIdAndUserId: (groupId, userId) =>
    cknex().select '*'
    .from 'bans_by_userId'
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .run()
    .map @deleteByBan
    .then ->
      key = "#{CacheService.PREFIXES.BAN_USER_ID}:#{groupId}:#{userId}"
      CacheService.deleteByKey key
    .then -> null

module.exports = new BanModel()
