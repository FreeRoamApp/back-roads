_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

cknex = require '../services/cknex'
CacheService = require '../services/cache'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

defaultGroupRole = (groupRole) ->
  unless groupRole?
    return null

  _.defaults groupRole, {
    uuid: cknex.getTimeUuid()
  }

defaultGroupRoleOutput = (groupRole) ->
  unless groupRole?
    return null

  groupRole.globalPermissions = try
    JSON.parse groupRole.globalPermissions
  catch error
    {}

  channelPermissions = groupRole.channelPermissions
  groupRole.channelPermissions = _.mapValues channelPermissions, (permission) ->
    try
      JSON.parse permission
    catch error
      {}

  groupRole

tables = [
  {
    name: 'group_roles_by_groupUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      groupUuid: 'uuid'
      name: 'text'
      globalPermissions: 'text' # json
      channelPermissions: {type: 'map', subType: 'uuid', subType2: 'text'}
    primaryKey:
      # a little uneven since some groups will have a lot of roles, but each
      # row is small
      partitionKey: ['groupUuid']
      clusteringColumns: ['uuid']
  }
]

class GroupRoleModel
  SCYLLA_TABLES: tables

  upsert: (groupRole, {map} = {}) ->
    groupRole = defaultGroupRole groupRole

    groupRole.globalPermissions = JSON.stringify groupRole.globalPermissions

    q = cknex().update 'group_roles_by_groupUuid'
    .set _.omit groupRole, ['groupUuid', 'uuid']

    if map
      _.forEach map, (value, column) ->
        q.add column, value
    q.where 'groupUuid', '=', groupRole.groupUuid
    .andWhere 'uuid', '=', groupRole.uuid
    .run()
    .then ->
      groupRole
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_ROLE_GROUP_UUID_USER_ID
      cacheKey = "#{prefix}:#{groupRole.groupUuid}:#{groupRole.userUuid}"
      prefix = CacheService.PREFIXES.GROUP_ROLES
      allCacheKey = "#{prefix}:#{groupRole.groupUuid}"
      Promise.all [
        CacheService.deleteByKey cacheKey
        CacheService.deleteByKey allCacheKey
      ]

  getAllByGroupUuid: (groupUuid, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'group_roles_by_groupUuid'
      .where 'groupUuid', '=', groupUuid
      .run()
      .then (roles) =>
        # probably safe to get rid of this in mid 2018
        if _.find roles, {name: 'everyone'}
          roles
        else
          @upsert {
            groupUuid: groupUuid
            name: 'everyone'
            globalPermissions: {}
          }
          .then =>
            @getAllByGroupUuid groupUuid
      .map defaultGroupRoleOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.GROUP_ROLES}:#{groupUuid}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getByGroupUuidAndRoleUuid: (groupUuid, uuid) ->
    cknex().select '*'
    .from 'group_roles_by_groupUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'uuid', '=', uuid
    .run {isSingle: true}
    .then defaultGroupRoleOutput

  deleteByGroupUuidAndRoleUuid: (groupUuid, uuid) ->
    cknex().delete()
    .from 'group_roles_by_groupUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'uuid', '=', uuid
    .run()

module.exports = new GroupRoleModel()
