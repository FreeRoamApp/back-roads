_ = require 'lodash'
Promise = require 'bluebird'
moment = require 'moment'
uuid = require 'node-uuid'

StreamService = require '../services/stream'
TimeService = require '../services/time'
CacheService = require '../services/cache'
cknex = require '../services/cknex'
Stream = require './stream'
config = require '../config'

defaultConversationMessage = (conversationMessage) ->
  unless conversationMessage?
    return null

  conversationMessage = _.defaults _.pickBy(conversationMessage), {
    id: cknex.getTimeUuid()
    clientId: uuid.v4()
    groupId: config.EMPTY_UUID
    timeBucket: TimeService.getScaledTimeByTimeScale 'week'
    lastUpdateTime: new Date()
    body: ''
  }
  if conversationMessage.card
    conversationMessage.card = try
      JSON.stringify conversationMessage.card
    catch err
      ''
  conversationMessage

defaultConversationMessageOutput = (conversationMessage) ->
  unless conversationMessage?
    return null

  if conversationMessage.groupId is config.EMPTY_UUID
    conversationMessage.groupId = null

  if conversationMessage.card
    conversationMessage.card = try
      JSON.parse conversationMessage.card
    catch err
      null

  conversationMessage

tables = [
  {
    name: 'conversation_messages_by_conversationId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      conversationId: 'uuid'
      clientId: 'uuid'
      userId: 'uuid'
      groupId: 'uuid'
      body: 'text'
      card: 'text'
      timeBucket: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['conversationId', 'timeBucket']
      clusteringColumns: ['id']
    withClusteringOrderBy: ['id', 'desc']
  }
  # for showing all of a user's messages, and potentially deleting all
  {
    name: 'conversation_messages_by_groupId_and_userId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      conversationId: 'uuid'
      clientId: 'uuid'
      userId: 'uuid'
      groupId: 'uuid'
      body: 'text'
      card: 'text'
      timeBucket: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['groupId', 'userId', 'timeBucket']
      clusteringColumns: ['id']
    withClusteringOrderBy: ['id', 'desc']
  }
  # for deleting by id
  {
    name: 'conversation_messages_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      conversationId: 'uuid'
      clientId: 'uuid'
      userId: 'uuid'
      groupId: 'uuid'
      body: 'text'
      card: 'text'
      timeBucket: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['id']
  }
]

class ConversationMessageModel extends Stream
  SCYLLA_TABLES: tables

  constructor: ->
    @streamChannelKey = 'conversation_message'
    @streamChannelsBy = ['conversationId']

  default: defaultConversationMessageOutput

  upsert: (conversationMessage, {prepareFn, isUpdate} = {}) =>
    conversationMessage = defaultConversationMessage conversationMessage

    Promise.all [
      cknex().update 'conversation_messages_by_conversationId'
      .set _.omit conversationMessage, [
        'conversationId', 'timeBucket', 'id'
      ]
      .where 'conversationId', '=', conversationMessage.conversationId
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'id', '=', conversationMessage.id
      .run()

      cknex().update 'conversation_messages_by_groupId_and_userId'
      .set _.omit conversationMessage, [
        'groupId', 'userId', 'timeBucket', 'id'
      ]
      .where 'groupId', '=', conversationMessage.groupId
      .andWhere 'userId', '=', conversationMessage.userId
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'id', '=', conversationMessage.id
      .run()

      cknex().update 'conversation_messages_by_id'
      .set _.omit conversationMessage, [
        'id'
      ]
      .where 'id', '=', conversationMessage.id
      .run()
    ]
    .then ->
      prepareFn?(conversationMessage) or conversationMessage
    .then (conversationMessage) =>
      unless isUpdate
        @streamCreate conversationMessage
      conversationMessage

  getAllByConversationId: (conversationId, options = {}) =>
    {limit, isStreamed, emit, socket, route, initialPostFn, postFn,
      minId, maxId, reverse} = options

    minTime = if minId \
              then cknex.getTimeUuidFromString(minId).getDate()
              else undefined

    maxTime = if maxId \
              then cknex.getTimeUuidFromString(maxId).getDate()
              else undefined

    timeBucket = TimeService.getScaledTimeByTimeScale(
      'week', moment(minTime or maxTime)
    )

    get = (timeBucket) ->
      q = cknex().select '*'
      .from 'conversation_messages_by_conversationId'
      .where 'conversationId', '=', conversationId
      .andWhere 'timeBucket', '=', timeBucket

      if minId
        q.andWhere 'id', '>=', minId
        q.orderBy 'id', 'ASC'

      if maxId
        q.andWhere 'id', '<', maxId

      q.limit limit
      .run()

    initial = get timeBucket
    .then (results) ->
      # if not enough results, check preivous time bucket. could do this more
      #  than once, but last 2 weeks of messages seems fine
      if limit and results.length < limit
        get TimeService.getPreviousTimeByTimeScale(
          'week', moment(minTime or maxTime)
        )
        .then (olderMessages) ->
          _.filter (results or []).concat olderMessages
      else
        results
    .then (results) ->
      if reverse
        results.reverse()
      results

    if isStreamed
      @stream {
        emit
        socket
        route
        initial
        initialPostFn
        postFn
        channelBy: 'conversationId'
        channelById: conversationId
      }
    else
      initial
      .map (initialPostFn or _.identity)

  unsubscribeByConversationId: (conversationId, {socket}) =>
    @unsubscribe {
      socket: socket
      channelBy: 'conversationId'
      channelById: conversationId
    }

  getAllByGroupIdAndUserIdAndTimeBucket: (groupId, userId, timeBucket) ->
    cknex().select '*'
    .from 'conversation_messages_by_groupId_and_userId'
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .andWhere 'timeBucket', '=', timeBucket
    .run()
    .map defaultConversationMessageOutput

  getById: (id) ->
    cknex().select '*'
    .from 'conversation_messages_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultConversationMessageOutput

  deleteByConversationMessage: (conversationMessage) =>
    Promise.all [
      cknex().delete()
      .from 'conversation_messages_by_conversationId'
      .where 'conversationId', '=', conversationMessage.conversationId
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'id', '=', conversationMessage.id
      .run()

      cknex().delete()
      .from 'conversation_messages_by_groupId_and_userId'
      .where 'groupId', '=', conversationMessage.groupId
      .andWhere 'userId', '=', conversationMessage.userId
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'id', '=', conversationMessage.id
      .run()

      cknex().delete()
      .from 'conversation_messages_by_id'
      .where 'id', '=', conversationMessage.id
      .run()
    ]
    .tap =>
      @streamDeleteById conversationMessage.id, conversationMessage

  getLastByConversationId: (conversationId) =>
    @getAllByConversationId conversationId, {limit: 1}
    .then (messages) ->
      messages?[0]
    .then defaultConversationMessageOutput

  updateById: (id, diff, {prepareFn}) =>
    @getById id
    .then defaultConversationMessageOutput
    .then (conversationMessage) =>
      updatedMessage = _.defaults(diff, conversationMessage)
      updatedMessage.lastUpdateTime = new Date()

      # hacky https://github.com/datastax/nodejs-driver/pull/243
      delete updatedMessage.get
      delete updatedMessage.values
      delete updatedMessage.keys
      delete updatedMessage.forEach

      @upsert updatedMessage, {isUpdate: true, prepareFn}
    .tap (conversationMessage) =>
      @streamUpdateById id, conversationMessage

  deleteAllByGroupIdAndUserId: (groupId, userId, {duration} = {}) =>
    duration ?= '7d' # TODO (doesn't actually do anything)

    del = (timeBucket) =>
      @getAllByGroupIdAndUserIdAndTimeBucket groupId, userId, timeBucket
      .map @deleteByConversationMessage

    del TimeService.getScaledTimeByTimeScale 'week'
    del TimeService.getScaledTimeByTimeScale(
      'week'
      moment().subtract(1, 'week')
    )

module.exports = new ConversationMessageModel()
