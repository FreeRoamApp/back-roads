_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
GroupRole = require './group_role'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

# don't run get all by groupId since some groups have 1m users

PERMISSIONS =
  ADMIN: 'admin'
  MANAGE_CHANNEL: 'manageChannel'
  MANAGE_PAGE: 'managePage'
  CREATE_MESSAGE: 'createMessage'
  READ_MESSAGE: 'readMessage'
  DELETE_MESSAGE: 'deleteMessage'
  DELETE_FORUM_THREAD: 'deleteForumThread'
  PIN_FORUM_THREAD: 'pinForumThread'
  DELETE_FORUM_COMMENT: 'deleteForumComment'
  PERMA_BAN_USER: 'permaBanUser'
  TEMP_BAN_USER: 'tempBanUser'
  UNBAN_USER: 'unbanUser'
  MENTION_EVERYONE: 'mentionEveryone'
  MANAGE_ROLE: 'manageRole'
  SEND_MESSAGE: 'sendMessage'
  SEND_IMAGE: 'sendImage'
  SEND_LINK: 'sendLink'
  SEND_ADDON: 'sendAddon'
  BYPASS_SLOW_MODE: 'bypassSlowMode'
  READ_AUDIT_LOG: 'readAuditLog'
  MANAGE_INFO: 'manageInfo'
  ADD_XP: 'addXp'

class GroupUserModel extends Base
  SCYLLA_TABLES: [
    {
      name: 'group_users_by_groupId'
      keyspace: 'free_roam'
      fields:
        groupId: 'uuid'
        userId: 'uuid'
        roleIds: {type: 'set', subType: 'uuid'}
        data: 'text'
        time: 'timestamp'
      primaryKey:
        # a little uneven since some groups will have a lot of users, but each
        # row is small...
        # TODO: probably sohuldn't add to group for public groups. dependent
        # on switching getCountByGroupId to use a counter.
        # 1/10/2018 largest row (500k users) is 20mb
        partitionKey: ['groupId']
        clusteringColumns: ['userId']
    }
    {
      name: 'group_users_by_userId'
      keyspace: 'free_roam'
      fields:
        groupId: 'uuid'
        userId: 'uuid'
        roleIds: {type: 'set', subType: 'uuid'}
        data: 'text'
        time: 'timestamp'
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: ['groupId']
    }
    {
      name: 'group_users_karma_counter_by_userId'
      keyspace: 'free_roam'
      ignoreUpsert: true
      fields:
        groupId: 'uuid'
        userId: 'uuid'
        karma: 'counter'
        level: 'counter'
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: ['groupId']
    }
    {
      name: 'group_users_counter_by_groupId'
      keyspace: 'free_roam'
      ignoreUpsert: true
      fields:
        groupId: 'uuid'
        userCount: 'counter'
      primaryKey:
        partitionKey: ['groupId']
    }
    {
      name: 'group_user_settings'
      keyspace: 'free_roam'
      ignoreUpsert: true
      fields:
        groupId: 'uuid'
        userId: 'uuid'
        globalNotifications: 'text'
        channelNotifications: {
          type: 'map', subType: 'uuid', subType2: 'text'
        }
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: ['groupId']
    }
  ]

  PERMISSIONS: PERMISSIONS

  upsert: (groupUser) =>
    super groupUser
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_USER_USER_ID
      cacheKey = "#{prefix}:#{groupUser.userId}"
      CacheService.deleteByKey cacheKey
      categoryPrefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
      categoryCacheKey = "#{categoryPrefix}:#{groupUser.userId}"
      CacheService.deleteByCategory categoryCacheKey

  create: (groupUser) =>
    Promise.all [
      @upsert groupUser
      @incrementCountByGroupId groupUser.groupId, 1
    ]

  addRoleIdByGroupUser: (groupUser, roleId) ->
    Promise.all [
      cknex().update 'group_users_by_groupId'
      .add 'roleIds', [[roleId]]
      .where 'groupId', '=', groupUser.groupId
      .andWhere 'userId', '=', groupUser.userId
      .run()

      cknex().update 'group_users_by_userId'
      .add 'roleIds', [[roleId]]
      .where 'userId', '=', groupUser.userId
      .andWhere 'groupId', '=', groupUser.groupId
      .run()
    ]
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_USER_USER_ID
      cacheKey = "#{prefix}:#{groupUser.userId}"
      CacheService.deleteByKey cacheKey
      categoryPrefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
      categoryCacheKey = "#{categoryPrefix}:#{groupUser.userId}"
      CacheService.deleteByCategory categoryCacheKey

  removeRoleIdByGroupUser: (groupUser, roleId) ->
    Promise.all [
      cknex().update 'group_users_by_groupId'
      .remove 'roleIds', [roleId]
      .where 'groupId', '=', groupUser.groupId
      .andWhere 'userId', '=', groupUser.userId
      .run()

      cknex().update 'group_users_by_userId'
      .remove 'roleIds', [roleId]
      .where 'userId', '=', groupUser.userId
      .andWhere 'groupId', '=', groupUser.groupId
      .run()
    ]
    .tap ->
      prefix = CacheService.PREFIXES.GROUP_USER_USER_ID
      cacheKey = "#{prefix}:#{groupUser.userId}"
      CacheService.deleteByKey cacheKey
      categoryPrefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
      categoryCacheKey = "#{categoryPrefix}:#{groupUser.userId}"
      CacheService.deleteByCategory categoryCacheKey

  getCountByGroupId: (groupId, {preferCache} = {}) ->
    get = ->
      cknex().select '*'
      .from 'group_users_counter_by_groupId'
      .where 'groupId', '=', groupId
      .run {isSingle: true}
      .then (response) ->
        response?.userCount or 0

    if preferCache
      cacheKey = "#{CacheService.PREFIXES.GROUP_USER_COUNT}:#{groupId}"
      CacheService.preferCache cacheKey, get, {
        expireSeconds: ONE_HOUR_SECONDS
      }
    else
      get()

  incrementCountByGroupId: (groupId, amount) ->
    cknex().update 'group_users_counter_by_groupId'
    .increment 'userCount', amount
    .where 'groupId', '=', groupId
    .run()

  getAllByUserId: (userId) ->
    cknex().select '*'
    .from 'group_users_by_userId'
    .where 'userId', '=', userId
    .run()

  getByGroupIdAndUserId: (groupId, userId) ->
    cknex().select '*'
    # .from 'group_users_by_groupId'
    .from 'group_users_by_userId'
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .run {isSingle: true}
    .then (groupUser) ->
      # so roles can still be embedded
      groupUser or {groupId}

  getXpByGroupIdAndUserId: (groupId, userId) ->
    cknex().select '*'
    .from 'group_users_karma_counter_by_userId'
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .run {isSingle: true}
    .then (groupUser) ->
      groupUser?.karma or 0

  getTopByGroupId: (groupId) ->
    prefix = CacheService.STATIC_PREFIXES.GROUP_LEADERBOARD
    key = "#{prefix}:#{groupId}"
    CacheService.leaderboardGet key
    .then (results) ->
      _.map _.chunk(results, 2), ([userId, karma], i) ->
        {
          rank: i + 1
          groupId
          userId
          karma: parseInt karma
        }

  incrementXpByGroupIdAndUserId: (groupId, userId, amount) ->
    updateXp = cknex().update 'group_users_karma_counter_by_userId'
    .increment 'karma', amount
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .run()

    Promise.all [
      updateXp

      prefix = CacheService.STATIC_PREFIXES.GROUP_LEADERBOARD
      key = "#{prefix}:#{groupId}"
      CacheService.leaderboardIncrement key, userId, amount, {
        currentValueFn: =>
          updateXp.then =>
            @getXpByGroupIdAndUserId groupId, userId
      }
    ]

  deleteByGroupIdAndUserId: (groupId, userId) =>
    Promise.all [
      cknex().delete()
      .from 'group_users_by_groupId'
      .where 'groupId', '=', groupId
      .andWhere 'userId', '=', userId
      .run()

      cknex().delete()
      .from 'group_users_by_userId'
      .where 'userId', '=', userId
      .andWhere 'groupId', '=', groupId
      .run()

      @incrementCountByGroupId groupId, -1
    ]

  getSettingsByGroupIdAndUserId: (groupId, userId) =>
    cknex().select '*'
    .from 'group_user_settings'
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .run {isSingle: true}
    .then @defaultGroupUserSettingsOutput

  upsertSettings: (settings) =>
    settings = @defaultGroupUserSettings settings

    cknex().update 'group_user_settings'
    .set _.omit settings, ['userId', 'groupId']
    .where 'groupId', '=', settings.groupId
    .andWhere 'userId', '=', settings.userId
    .run()

  hasPermissionByGroupIdAndUser: (groupId, user, permissions, options) =>
    options ?= {}
    {channelId} = options

    @getByGroupIdAndUserId groupId, user.id
    .then (groupUser) =>
      groupUser or= {}
      GroupRole.getAllByGroupId groupId, {preferCache: true}
      .then (roles) ->
        everyoneRole = _.find roles, {name: 'everyone'}
        groupUserRoles = _.filter _.map groupUser.roleIds, (roleId) ->
          _.find roles, (role) ->
            "#{role.id}" is "#{roleId}"
        if everyoneRole
          groupUserRoles = groupUserRoles.concat everyoneRole
        groupUser.roles = groupUserRoles
        groupUser
      .then =>
        @hasPermission {
          meGroupUser: groupUser
          permissions: permissions
          channelId: channelId
          me: user
        }

  hasPermission: ({meGroupUser, me, permissions, channelId}) ->
    isGlobalModerator = me?.flags?.isModerator or me?.username is 'austin'
    isGlobalModerator or _.every permissions, (permission) ->
      _.find meGroupUser?.roles, (role) ->
        channelPermissions = channelId and role.channelPermissions?[channelId]
        globalPermissions = role.globalPermissions
        permissions = _.defaults(
          channelPermissions, globalPermissions, config.DEFAULT_PERMISSIONS
        )
        permissions[permission]

  defaultInput: (groupUser) ->
    unless groupUser?
      return null

    _.defaults groupUser, {
      time: new Date()
    }

  defaultGroupUserSettings: (groupUserSettings) ->
    unless groupUserSettings?
      return null

    groupUserSettings.globalNotifications = JSON.stringify(
      groupUserSettings.globalNotifications
    )

    groupUserSettings

  defaultGroupUserSettingsOutput: (groupUserSettings) ->
    unless groupUserSettings?
      return null

    groupUserSettings.globalNotifications = try
      JSON.parse groupUserSettings.globalNotifications
    catch error
      {}

    groupUserSettings


module.exports = new GroupUserModel()
