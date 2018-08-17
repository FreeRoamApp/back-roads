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
    uuid: cknex.getTimeUuid()
  }

ONE_DAY_SECONDS = 3600 * 24
ONE_MONTH_SECONDS = 3600 * 24 * 31

tables = [
  {
    name: 'bans_by_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      bannedByUuid: 'uuid'
      duration: 'text'
      ip: 'text'
    primaryKey:
      partitionKey: ['groupUuid']
      clusteringColumns: ['userUuid']
  }
  {
    name: 'bans_by_ip'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      bannedByUuid: 'uuid'
      duration: 'text'
      ip: 'text'
    primaryKey:
      partitionKey: ['groupUuid']
      clusteringColumns: ['ip']
  }
  {
    name: 'bans_by_duration_and_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      bannedByUuid: 'uuid'
      duration: 'text'
      ip: 'text'
    primaryKey:
      partitionKey: ['groupUuid', 'duration']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
]

class BanModel
  SCYLLA_TABLES: tables

  upsert: (ban, {ttl} = {}) ->
    ban = defaultBan ban

    queries = [
      cknex().update 'bans_by_userUuid'
      .set _.omit ban, [
        'groupUuid', 'userUuid'
      ]
      .where 'groupUuid', '=', ban.groupUuid
      .andWhere 'userUuid', '=', ban.userUuid

      cknex().update 'bans_by_ip'
      .set _.omit ban, [
        'groupUuid', 'ip'
      ]
      .where 'groupUuid', '=', ban.groupUuid
      .andWhere 'ip', '=', ban.ip

      cknex().update 'bans_by_duration_and_uuid'
      .set _.omit ban, [
        'groupUuid', 'duration', 'uuid'
      ]
      .where 'groupUuid', '=', ban.groupUuid
      .andWhere 'duration', '=', ban.duration
      .andWhere 'uuid', '=', ban.uuid
    ]

    if ttl
      queries = _.map queries, (query) ->
        query.usingTTL ttl

    Promise.all _.map queries, (query) ->
      query.run()
    .then ->
      if ban.userUuid
        prefix = CacheService.PREFIXES.BAN_USER_ID
        key = "#{prefix}:#{ban.groupUuid}:#{ban.userUuid}"
        CacheService.deleteByKey key
      if ban.ip
        prefix = CacheService.PREFIXES.BAN_IP
        key = "#{prefix}:#{ban.groupUuid}:#{ban.ip}"
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

  getAllByGroupUuidAndDuration: (groupUuid, duration) ->
    cknex().select '*'
    .from 'bans_by_duration_and_uuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'duration', '=', duration
    .limit 100
    .run()
    .map defaultBan

  getByGroupUuidAndIp: (groupUuid, ip, {scope, preferCache} = {}) ->
    scope ?= 'chat'

    get = ->
      cknex().select '*'
      .from 'bans_by_ip'
      .where 'groupUuid', '=', groupUuid
      .andWhere 'ip', '=', ip
      .run {isSingle: true}
      .then defaultBan

    if preferCache
      key = "#{CacheService.PREFIXES.BAN_IP}:#{groupUuid}:#{ip}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_SECONDS}
    else
      get()

  getByGroupUuidAndUserUuid: (groupUuid, userUuid, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'bans_by_userUuid'
      .where 'groupUuid', '=', groupUuid
      .andWhere 'userUuid', '=', userUuid
      .run {isSingle: true}
      .then defaultBan

    if preferCache
      key = "#{CacheService.PREFIXES.BAN_USER_ID}:#{groupUuid}:#{userUuid}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_SECONDS}
    else
      get()

  deleteByBan: (ban) ->
    Promise.all _.filter [
      cknex().delete()
      .from 'bans_by_userUuid'
      .where 'groupUuid', '=', ban.groupUuid
      .andWhere 'userUuid', '=', ban.userUuid
      .run()

      if ban.ip
        cknex().delete()
        .from 'bans_by_ip'
        .where 'groupUuid', '=', ban.groupUuid
        .andWhere 'ip', '=', ban.ip
        .run()

      cknex().delete()
      .from 'bans_by_duration_and_uuid'
      .where 'groupUuid', '=', ban.groupUuid
      .andWhere 'duration', '=', ban.duration
      .andWhere 'uuid', '=', ban.uuid
      .run()
    ]

  deleteAllByGroupUuidAndIp: (groupUuid, ip) =>
    cknex().select '*'
    .from 'bans_by_userUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'ip', '=', ip
    .run()
    .map @deleteByBan
    .then ->
      key = "#{CacheService.PREFIXES.BAN_IP}:#{groupUuid}:#{ip}"
      CacheService.deleteByKey key
    .then -> null

  deleteAllByGroupUuidAndUserUuid: (groupUuid, userUuid) =>
    cknex().select '*'
    .from 'bans_by_userUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'userUuid', '=', userUuid
    .run()
    .map @deleteByBan
    .then ->
      key = "#{CacheService.PREFIXES.BAN_USER_ID}:#{groupUuid}:#{userUuid}"
      CacheService.deleteByKey key
    .then -> null

module.exports = new BanModel()
