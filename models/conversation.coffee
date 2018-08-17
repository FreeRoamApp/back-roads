_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
Group = require './group'

ONE_DAY_S = 3600 * 24

defaultConversation = (conversation) ->
  unless conversation?
    return null

  conversation.uuid ?= cknex.getTimeUuid conversation.lastUpdateTime
  conversation.data = JSON.stringify conversation.data

  conversation

defaultConversationOutput = (conversation) ->
  unless conversation?
    return null

  conversation.data = try
    JSON.parse conversation.data
  catch err
    {}

  conversation.userUuids = _.map conversation.userUuids, (userUuid) -> "#{userUuid}"
  conversation.uuid = "#{conversation.uuid}"
  if conversation.userUuid
    conversation.userUuid = "#{conversation.userUuid}"
  if conversation.groupUuid
    conversation.groupUuid = "#{conversation.groupUuid}"

  conversation

tables = [
  {
    name: 'conversations_by_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid' # not unique - 1 row per userUuid
      userUuid: 'uuid'
      userUuids: {type: 'set', subType: 'uuid'}
      groupUuid: 'uuid'
      type: 'text'
      data: 'text' # json: name, description, slowMode, slowModeCooldown
      isRead: 'boolean'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  {
    name: 'conversations_by_groupUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid' # not unique - 1 row per userUuid
      userUuid: 'uuid'
      userUuids: {type: 'set', subType: 'uuid'}
      groupUuid: 'uuid'
      type: 'text'
      data: 'text' # json: name, description, slowMode, slowModeCooldown
      isRead: 'boolean'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['groupUuid']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  {
    name: 'conversations_by_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      userUuid: 'uuid'
      userUuids: {type: 'set', subType: 'uuid'}
      groupUuid: 'uuid'
      type: 'text'
      data: 'text' # json: name, description, slowMode, slowModeCooldown
      isRead: 'boolean'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['uuid']
      clusteringColumns: null
  }
]

class ConversationModel
  SCYLLA_TABLES: tables

  upsert: (conversation, {userUuid} = {}) ->
    conversation = defaultConversation conversation

    Promise.all _.filter _.flatten [
      _.map conversation.userUuids, (conversationUserUuid) ->
        conversation.isRead = conversationUserUuid is userUuid
        cknex().update 'conversations_by_userUuid'
        .set _.omit conversation, ['userUuid', 'uuid']
        .where 'userUuid', '=', conversationUserUuid
        .andWhere 'uuid', '=', conversation.uuid
        .run()

      if conversation.groupUuid
        cknex().update 'conversations_by_groupUuid'
        .set _.omit conversation, ['groupUuid', 'uuid']
        .where 'groupUuid', '=', conversation.groupUuid
        .andWhere 'uuid', '=', conversation.uuid
        .run()

      cknex().update 'conversations_by_uuid'
      .set _.omit conversation, ['uuid']
      .where 'uuid', '=', conversation.uuid
      .run()
    ]
    .tap ->
      prefix = CacheService.PREFIXES.CONVERSATION_UUID
      key = "#{prefix}:#{conversation.uuid}"
      CacheService.deleteByKey key
    .then ->
      conversation

  getByUuid: (uuid, {preferCache} = {}) ->
    preferCache ?= true
    get = ->
      cknex().select '*'
      .from 'conversations_by_uuid'
      .where 'uuid', '=', uuid
      .run {isSingle: true}
      .then defaultConversationOutput
      .catch (err) ->
        console.log 'covnersation get err', uuid
        throw err

    if preferCache
      prefix = CacheService.PREFIXES.CONVERSATION_UUID
      key = "#{prefix}:#{uuid}"
      CacheService.preferCache key, get, {expireSeconds: ONE_DAY_S}
    else
      get()

  getByGroupUuidAndName: (groupUuid, name) =>
    @getAllByGroupUuid groupUuid
    .then (conversations) ->
      _.find conversations, {name}
    .then defaultConversationOutput

  getAllByUserUuid: (userUuid, {limit} = {}) ->
    limit ?= 10

    # TODO: use a redis leaderboard for sorting by last update?
    cknex().select '*'
    .from 'conversations_by_userUuid'
    .where 'userUuid', '=', userUuid
    .limit 1000
    .run()
    .then (conversations) ->
      conversations = _.filter conversations, (conversation) ->
        conversation.type is 'pm' and conversation.lastUpdateTime
      conversations = _.orderBy conversations, 'lastUpdateTime', 'desc'
      conversations = _.take conversations, limit
    .map defaultConversationOutput

  getAllByGroupUuid: (groupUuid) ->
    cknex().select '*'
    .from 'conversations_by_groupUuid'
    .where 'groupUuid', '=', groupUuid
    .run()
    .map defaultConversationOutput

  getByUserUuids: (checkUserUuids, {limit} = {}) =>
    @getAllByUserUuid checkUserUuids[0], {limit: 2500}
    .then (conversations) ->
      _.find conversations, ({type, userUuids}) ->
        type is 'pm' and _.every checkUserUuids, (userUuid) ->
          userUuids.indexOf(userUuid) isnt -1
    .then defaultConversation

  markRead: ({uuid}, userUuid) ->
    cknex().update 'conversations_by_userUuid'
    .set {isRead: true}
    .where 'userUuid', '=', userUuid
    .andWhere 'uuid', '=', uuid
    .run()

  sanitize: _.curry (requesterId, conversation) ->
    _.pick conversation, [
      'uuid'
      'userUuids'
      'data'
      'users'
      'groupUuid'
      'lastUpdateTime'
      'lastMessage'
      'isRead'
      'embedded'
    ]

module.exports = new ConversationModel()
