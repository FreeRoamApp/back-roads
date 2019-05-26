_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

# TODO: true/false/non-existent
# TODO: group_role priority ordering. will take value from highest priority role`
# TODO: if permission is non-existent for a role, defer to next highest priority role

class GroupRoleModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'group_roles_by_groupId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          groupId: 'uuid'
          name: 'text'
          globalPermissions: 'json' # json
          channelPermissions: {type: 'map', subType: 'uuid', subType2: 'text'}
        primaryKey:
          # a little uneven since some groups will have a lot of roles, but each
          # row is small
          partitionKey: ['groupId']
          clusteringColumns: ['id']
      }
    ]

  upsert: (groupRole, options) =>
    super groupRole, options
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
      .map @defaultOutput

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.GROUP_ROLES}:#{groupId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  getByGroupIdAndRoleId: (groupId, id) =>
    cknex().select '*'
    .from 'group_roles_by_groupId'
    .where 'groupId', '=', groupId
    .andWhere 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  deleteByGroupIdAndRoleId: (groupId, id) ->
    cknex().delete()
    .from 'group_roles_by_groupId'
    .where 'groupId', '=', groupId
    .andWhere 'id', '=', id
    .run()

  defaultOutput: (groupRole) ->
    groupRole = super groupRole

    channelPermissions = groupRole.channelPermissions
    groupRole.channelPermissions = _.mapValues channelPermissions, (permission) ->
      try
        JSON.parse permission
      catch error
        {}

    groupRole

module.exports = new GroupRoleModel()
