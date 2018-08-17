_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
GroupRole = require './group_role'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

# don't run get all by groupUuid since some groups have 1m users

defaultGroupUser = (groupUser) ->
  unless groupUser?
    return null

  _.defaults groupUser, {
    time: new Date()
  }

defaultGroupUserSettings = (groupUserSettings) ->
  unless groupUserSettings?
    return null

  groupUserSettings.globalNotifications = JSON.stringify(
    groupUserSettings.globalNotifications
  )

  groupUserSettings

defaultGroupUserSettingsOutput = (groupUserSettings) ->
  unless groupUserSettings?
    return null

  groupUserSettings.globalNotifications = try
    JSON.parse groupUserSettings.globalNotifications
  catch error
    {}

  groupUserSettings

tables = [
  {
    name: 'group_users_by_groupUuid'
    keyspace: 'free_roam'
    fields:
      groupUuid: 'uuid'
      userUuid: 'uuid'
      roleUuids: {type: 'set', subType: 'uuid'}
      data: 'text'
      time: 'timestamp'
    primaryKey:
      # a little uneven since some groups will have a lot of users, but each
      # row is small...
      # TODO: probably sohuldn't add to group for public groups. dependent
      # on switching getCountByGroupUuid to use a counter.
      # 1/10/2018 largest row (500k users) is 20mb
      partitionKey: ['groupUuid']
      clusteringColumns: ['userUuid']
  }
  {
    name: 'group_users_by_userUuid'
    keyspace: 'free_roam'
    fields:
      groupUuid: 'uuid'
      userUuid: 'uuid'
      roleUuids: {type: 'set', subType: 'uuid'}
      data: 'text'
      time: 'timestamp'
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['groupUuid']
  }
  {
    name: 'group_users_karma_counter_by_userUuid'
    keyspace: 'free_roam'
    fields:
      groupUuid: 'uuid'
      userUuid: 'uuid'
      karma: 'counter'
      level: 'counter'
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['groupUuid']
  }
  {
    name: 'group_users_counter_by_groupUuid'
    keyspace: 'free_roam'
    fields:
      groupUuid: 'uuid'
      userCount: 'counter'
    primaryKey:
      partitionKey: ['groupUuid']
  }
  {
    name: 'group_user_settings'
    keyspace: 'free_roam'
    fields:
      groupUuid: 'uuid'
      userUuid: 'uuid'
      globalNotifications: 'text'
      channelNotifications: {
        type: 'map', subType: 'uuid', subType2: 'text'
      }
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['groupUuid']
  }
]

PERMISSIONS =
  ADMIN: 'admin'
  MANAGE_CHANNEL: 'manageChannel'
  MANAGE_PAGE: 'managePage'
  READ_MESSAGE: 'readMessage'
  DELETE_MESSAGE: 'deleteMessage'
  DELETE_FORUM_THREAD: 'deleteForumThread'
  PIN_FORUM_THREAD: 'pinForumThread'
  DELETE_FORUM_COMMENT: 'deleteForumComment'
  PERMA_BAN_USER: 'permaBanUser'
  TEMP_BAN_USER: 'tempBanUser'
  UNBAN_USER: 'unbanUser'
  MANAGE_ROLE: 'manageRole'
  SEND_MESSAGE: 'sendMessage'
  SEND_IMAGE: 'sendImage'
  SEND_LINK: 'sendLink'
  SEND_ADDON: 'sendAddon'
  BYPASS_SLOW_MODE: 'bypassSlowMode'
  READ_AUDIT_LOG: 'readAuditLog'
  MANAGE_INFO: 'manageInfo'
  ADD_XP: 'addXp'

class GroupUserModel
  SCYLLA_TABLES: tables
  PERMISSIONS: PERMISSIONS

  upsert: (groupUser) ->
    groupUser = defaultGroupUser groupUser

    Promise.all [
      cknex().update 'group_users_by_groupUuid'
      .set _.omit groupUser, ['userUuid', 'groupUuid']
      .where 'groupUuid', '=', groupUser.groupUuid
      .andWhere 'userUuid', '=', groupUser.userUuid
      .run()

      cknex().update 'group_users_by_userUuid'
      .set _.omit groupUser, ['userUuid', 'groupUuid']
      .where 'userUuid', '=', groupUser.userUuid
      .andWhere 'groupUuid', '=', groupUser.groupUuid
      .run()
    ]
    .then ->
      groupUser
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_USER_USER_ID
      cacheKey = "#{prefix}:#{groupUser.userUuid}"
      CacheService.deleteByKey cacheKey
      categoryPrefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
      categoryCacheKey = "#{categoryPrefix}:#{groupUser.userUuid}"
      CacheService.deleteByCategory categoryCacheKey

  create: (groupUser) =>
    Promise.all [
      @upsert groupUser
      @incrementCountByGroupUuid groupUser.groupUuid, 1
    ]

  addRoleUuidByGroupUser: (groupUser, roleUuid) ->
    Promise.all [
      cknex().update 'group_users_by_groupUuid'
      .add 'roleUuids', [[roleUuid]]
      .where 'groupUuid', '=', groupUser.groupUuid
      .andWhere 'userUuid', '=', groupUser.userUuid
      .run()

      cknex().update 'group_users_by_userUuid'
      .add 'roleUuids', [[roleUuid]]
      .where 'userUuid', '=', groupUser.userUuid
      .andWhere 'groupUuid', '=', groupUser.groupUuid
      .run()
    ]
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_USER_USER_ID
      cacheKey = "#{prefix}:#{groupUser.userUuid}"
      CacheService.deleteByKey cacheKey
      categoryPrefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
      categoryCacheKey = "#{categoryPrefix}:#{groupUser.userUuid}"
      CacheService.deleteByCategory categoryCacheKey

  removeRoleUuidByGroupUser: (groupUser, roleUuid) ->
    Promise.all [
      cknex().update 'group_users_by_groupUuid'
      .remove 'roleUuids', [roleUuid]
      .where 'groupUuid', '=', groupUser.groupUuid
      .andWhere 'userUuid', '=', groupUser.userUuid
      .run()

      cknex().update 'group_users_by_userUuid'
      .remove 'roleUuids', [roleUuid]
      .where 'userUuid', '=', groupUser.userUuid
      .andWhere 'groupUuid', '=', groupUser.groupUuid
      .run()
    ]
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_USER_USER_ID
      cacheKey = "#{prefix}:#{groupUser.userUuid}"
      CacheService.deleteByKey cacheKey
      categoryPrefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
      categoryCacheKey = "#{categoryPrefix}:#{groupUser.userUuid}"
      CacheService.deleteByCategory categoryCacheKey

  getCountByGroupUuid: (groupUuid, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'group_users_counter_by_groupUuid'
      .where 'groupUuid', '=', groupUuid
      .run {isSingle: true}
      .then (response) ->
        response?.userCount or 0

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.GROUP_USER_COUNT}:#{groupUuid}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  incrementCountByGroupUuid: (groupUuid, amount) ->
    cknex().update 'group_users_counter_by_groupUuid'
    .increment 'userCount', amount
    .where 'groupUuid', '=', groupUuid
    .run()

  getAllByUserUuid: (userUuid) ->
    cknex().select '*'
    .from 'group_users_by_userUuid'
    .where 'userUuid', '=', userUuid
    .run()

  getByGroupUuidAndUserUuid: (groupUuid, userUuid) ->
    cknex().select '*'
    # .from 'group_users_by_groupUuid'
    .from 'group_users_by_userUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'userUuid', '=', userUuid
    .run {isSingle: true}
    .then (groupUser) ->
      # so roles can still be embedded
      groupUser or {groupUuid}

  getXpByGroupUuidAndUserUuid: (groupUuid, userUuid) ->
    cknex().select '*'
    .from 'group_users_karma_counter_by_userUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'userUuid', '=', userUuid
    .run {isSingle: true}
    .then (groupUser) ->
      groupUser?.karma or 0

  getTopByGroupUuid: (groupUuid) ->
    prefix = CacheService.STATIC_PREFIXES.GROUP_LEADERBOARD
    key = "#{prefix}:#{groupUuid}"
    CacheService.leaderboardGet key
    .then (results) ->
      _.map _.chunk(results, 2), ([userUuid, karma], i) ->
        {
          rank: i + 1
          groupUuid
          userUuid
          karma: parseInt karma
        }

  incrementXpByGroupUuidAndUserUuid: (groupUuid, userUuid, amount) ->
    updateXp = cknex().update 'group_users_karma_counter_by_userUuid'
    .increment 'karma', amount
    .where 'groupUuid', '=', groupUuid
    .andWhere 'userUuid', '=', userUuid
    .run()

    Promise.all [
      updateXp

      prefix = CacheService.STATIC_PREFIXES.GROUP_LEADERBOARD
      key = "#{prefix}:#{groupUuid}"
      CacheService.leaderboardIncrement key, userUuid, amount, {
        currentValueFn: =>
          updateXp.then =>
            @getXpByGroupUuidAndUserUuid groupUuid, userUuid
      }
    ]

  deleteByGroupUuidAndUserUuid: (groupUuid, userUuid) =>
    Promise.all [
      cknex().delete()
      .from 'group_users_by_groupUuid'
      .where 'groupUuid', '=', groupUuid
      .andWhere 'userUuid', '=', userUuid
      .run()

      cknex().delete()
      .from 'group_users_by_userUuid'
      .where 'userUuid', '=', userUuid
      .andWhere 'groupUuid', '=', groupUuid
      .run()

      @incrementCountByGroupUuid groupUuid, -1
    ]

  getSettingsByGroupUuidAndUserUuid: (groupUuid, userUuid) ->
    cknex().select '*'
    .from 'group_user_settings'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'userUuid', '=', userUuid
    .run {isSingle: true}
    .then defaultGroupUserSettingsOutput

  upsertSettings: (settings) ->
    settings = defaultGroupUserSettings settings

    cknex().update 'group_user_settings'
    .set _.omit settings, ['userUuid', 'groupUuid']
    .where 'groupUuid', '=', settings.groupUuid
    .andWhere 'userUuid', '=', settings.userUuid
    .run()

  hasPermissionByGroupUuidAndUser: (groupUuid, user, permissions, options) =>
    options ?= {}
    {channelUuid} = options

    @getByGroupUuidAndUserUuid groupUuid, user.uuid
    .then (groupUser) =>
      groupUser or= {}
      GroupRole.getAllByGroupUuid groupUuid, {preferCache: true}
      .then (roles) ->
        everyoneRole = _.find roles, {name: 'everyone'}
        groupUserRoles = _.filter _.map groupUser.roleUuids, (roleUuid) ->
          _.find roles, (role) ->
            "#{role.roleUuid}" is "#{roleUuid}"
        if everyoneRole
          groupUserRoles = groupUserRoles.concat everyoneRole
        groupUser.roles = groupUserRoles
        groupUser
      .then =>
        @hasPermission {
          meGroupUser: groupUser
          permissions: permissions
          channelUuid: channelUuid
          me: user
        }

  hasPermission: ({meGroupUser, me, permissions, channelUuid}) ->
    isGlobalModerator = me?.flags?.isModerator
    isGlobalModerator or _.every permissions, (permission) ->
      _.find meGroupUser?.roles, (role) ->
        channelPermissions = channelUuid and role.channelPermissions?[channelUuid]
        globalPermissions = role.globalPermissions
        permissions = _.defaults(
          channelPermissions, globalPermissions, config.DEFAULT_PERMISSIONS
        )
        permissions[permission]


module.exports = new GroupUserModel()
