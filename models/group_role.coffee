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
    id: cknex.getTimeUuid()
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
    name: 'group_roles_by_groupId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      groupId: 'uuid'
      name: 'text'
      globalPermissions: 'text' # json
      channelPermissions: {type: 'map', subType: 'uuid', subType2: 'text'}
    primaryKey:
      # a little uneven since some groups will have a lot of roles, but each
      # row is small
      partitionKey: ['groupId']
      clusteringColumns: ['id']
  }
]

class GroupRoleModel
  SCYLLA_TABLES: tables

  upsert: (groupRole, {map} = {}) ->
    groupRole = defaultGroupRole groupRole

    groupRole.globalPermissions = JSON.stringify groupRole.globalPermissions

    q = cknex().update 'group_roles_by_groupId'
    .set _.omit groupRole, ['groupId', 'id']

    if map
      _.forEach map, (value, column) ->
        q.add column, value
    q.where 'groupId', '=', groupRole.groupId
    .andWhere 'id', '=', groupRole.id
    .run()
    .then ->
      groupRole
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_ROLE_GROUP_ID_USER_ID
      cacheKey = "#{prefix}:#{groupRole.groupId}:#{groupRole.userId}"
      prefix = CacheService.PREFIXES.GROUP_ROLES
      allCacheKey = "#{prefix}:#{groupRole.groupId}"
      Promise.all [
        CacheService.deleteByKey cacheKey
        CacheService.deleteByKey allCacheKey
      ]

  getAllByGroupId: (groupId, {preferCache} = {}) =>
    get = =>
      cknex().select '*'
      .from 'group_roles_by_groupId'
      .where 'groupId', '=', groupId
      .run()
      .then (roles) =>
        # probably safe to get rid of this in mid 2018
        if _.find roles, {name: 'everyone'}
          roles
        else
          @upsert {
            groupId: groupId
            name: 'everyone'
            globalPermissions: {}
          }
          .then =>
            @getAllByGroupId groupId
      .map defaultGroupRoleOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.GROUP_ROLES}:#{groupId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getByGroupIdAndRoleId: (groupId, id) ->
    cknex().select '*'
    .from 'group_roles_by_groupId'
    .where 'groupId', '=', groupId
    .andWhere 'id', '=', id
    .run {isSingle: true}
    .then defaultGroupRoleOutput

  deleteByGroupIdAndRoleId: (groupId, id) ->
    cknex().delete()
    .from 'group_roles_by_groupId'
    .where 'groupId', '=', groupId
    .andWhere 'id', '=', id
    .run()

module.exports = new GroupRoleModel()
