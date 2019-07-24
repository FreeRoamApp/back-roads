_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
GroupRole = require './group_role'
GroupUser = require './group_user'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
Group = require './group'

ONE_DAY_S = 3600 * 24

scyllaFields =
  id: 'timeuuid'
  slug: 'text'
  userId: 'uuid'
  userIds: {type: 'set', subType: 'uuid'}
  groupId: 'uuid'
  type: 'text'
  rank: 'int' # ordering
  data: 'json' # json: name, description, slowMode, slowModeCooldown, isDefault
  isRead: 'boolean'
  lastUpdateTime: 'timestamp'

class ConversationModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'conversations_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'conversations_by_groupId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['groupId']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'conversations_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
          clusteringColumns: null
      }
      {
        name: 'conversations_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['slug']
          clusteringColumns: null
      }
    ]

  upsert: (conversation, {userId} = {}) =>
    conversation = @defaultInput conversation

    Promise.all _.filter _.flatten [
      _.map conversation.userIds, (conversationUserId) ->
        conversation.isRead = "#{conversationUserId}" is "#{userId}"
        cknex().update 'conversations_by_userId'
        .set _.omit conversation, ['userId', 'id']
        .where 'userId', '=', conversationUserId
        .andWhere 'id', '=', conversation.id
        .run()

      if conversation.groupId
        cknex().update 'conversations_by_groupId'
        .set _.omit conversation, ['groupId', 'id']
        .where 'groupId', '=', conversation.groupId
        .andWhere 'id', '=', conversation.id
        .run()

      cknex().update 'conversations_by_id'
      .set _.omit conversation, ['id']
      .where 'id', '=', conversation.id
      .run()
    ]
    .tap ->
      prefix = CacheService.PREFIXES.CONVERSATION_ID
      key = "#{prefix}:#{conversation.id}"
      CacheService.deleteByKey key
    .then ->
      conversation

  getById: (id, {preferCache} = {}) =>
    preferCache ?= true
    get = =>
      cknex().select '*'
      .from 'conversations_by_id'
      .where 'id', '=', id
      .run {isSingle: true}
      .then @defaultOutput
      .catch (err) ->
        console.log 'conversation get err', id
        throw err

    if preferCache
      prefix = CacheService.PREFIXES.CONVERSATION_ID
      key = "#{prefix}:#{id}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_S}
    else
      get()

  getByGroupIdAndName: (groupId, name) =>
    @getAllByGroupId groupId
    .then (conversations) ->
      _.find conversations, {name}
    .then @defaultOutput

  getAllByUserId: (userId, {limit, hasMessages} = {}) =>
    limit ?= 25

    # FIXME FIXME: use a redis leaderboard for sorting by last update?
    cknex().select '*'
    .from 'conversations_by_userId'
    .where 'userId', '=', userId
    .limit 2000
    .run()
    .then (conversations) ->
      if hasMessages
        conversations = _.filter conversations, (conversation) ->
          conversation.type is 'pm' and conversation.lastUpdateTime
      conversations = _.orderBy conversations, 'lastUpdateTime', 'desc'
      conversations = _.take conversations, limit
    .map @defaultOutput

  getAllByGroupId: (groupId) =>
    cknex().select '*'
    .from 'conversations_by_groupId'
    .where 'groupId', '=', groupId
    .run()
    .map @defaultOutput

  getDefaultByGroup: (group) =>
    if group.data?.welcomeChannelId
      @getById group.data?.welcomeChannelId
    else
      Promise.resolve null

  getByUserIds: (checkUserIds, {limit} = {}) =>
    @getAllByUserId checkUserIds[0], {limit: 2500}
    .then (conversations) ->
      _.find conversations, ({type, userIds}) ->
        userIds = _.map userIds, (userId) -> "#{userId}"
        type is 'pm' and _.every checkUserIds, (userId) ->
          userIds.indexOf("#{userId}") isnt -1
    .then @defaultOutput

  getAllPublicByGroupId: (groupId, {preferCache} = {}) =>
    preferCache ?= true

    get = =>
      Promise.all [
        @getAllByGroupId groupId
        GroupRole.getAllByGroupId groupId, {preferCache}
      ]
      .then ([conversations, roles]) ->
        everyoneRole = _.find roles, {name: 'everyone'}

        publicChannels = _.filter conversations, (conversation) ->
          GroupUser.hasPermission {
            meGroupUser: {
              roles: [everyoneRole]
            }
            permissions: [GroupUser.PERMISSIONS.READ_MESSAGE]
            channelId: conversation.id
          }

    if preferCache
      prefix = CacheService.PREFIXES.PUBLIC_CHANNELS_BY_GROUP_ID
      key = "#{prefix}:#{groupId}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_S}
    else
      get()


  markRead: ({id}, userId) ->
    cknex().update 'conversations_by_userId'
    .set {isRead: true}
    .where 'userId', '=', userId
    .andWhere 'id', '=', id
    .run()

  pmHasPermission: (conversation, userId) ->
    Promise.resolve userId and _.some conversation.userIds, (convUserId) ->
      "#{convUserId}" is "#{userId}"

  sanitize: _.curry (requesterId, conversation) ->
    _.pick conversation, [
      'id'
      'userIds'
      'data'
      'users'
      'groupId'
      'lastUpdateTime'
      'lastMessage'
      'isRead'
      'rank'
      'embedded'
    ]

module.exports = new ConversationModel()
