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
    uuid: cknex.getTimeUuid()
    clientUuid: uuid.v4()
    groupUuid: config.EMPTY_UUID
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

  if conversationMessage.groupUuid is config.EMPTY_UUID
    conversationMessage.groupUuid = null

  if conversationMessage.card
    conversationMessage.card = try
      JSON.parse conversationMessage.card
    catch err
      null

  conversationMessage

tables = [
  {
    name: 'conversation_messages_by_conversationUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      conversationUuid: 'uuid'
      clientUuid: 'uuid'
      userUuid: 'uuid'
      groupUuid: 'uuid'
      body: 'text'
      card: 'text'
      timeBucket: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['conversationUuid', 'timeBucket']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  # for showing all of a user's messages, and potentially deleting all
  {
    name: 'conversation_messages_by_groupUuid_and_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      conversationUuid: 'uuid'
      clientUuid: 'uuid'
      userUuid: 'uuid'
      groupUuid: 'uuid'
      body: 'text'
      card: 'text'
      timeBucket: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['groupUuid', 'userUuid', 'timeBucket']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  # for deleting by id
  {
    name: 'conversation_messages_by_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      conversationUuid: 'uuid'
      clientUuid: 'uuid'
      userUuid: 'uuid'
      groupUuid: 'uuid'
      body: 'text'
      card: 'text'
      timeBucket: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['uuid']
  }
]

class ConversationMessageModel extends Stream
  SCYLLA_TABLES: tables

  constructor: ->
    @streamChannelKey = 'conversation_message'
    @streamChannelsBy = ['conversationUuid']

  default: defaultConversationMessageOutput

  upsert: (conversationMessage, {prepareFn, isUpdate} = {}) =>
    conversationMessage = defaultConversationMessage conversationMessage

    Promise.all [
      cknex().update 'conversation_messages_by_conversationUuid'
      .set _.omit conversationMessage, [
        'conversationUuid', 'timeBucket', 'uuid'
      ]
      .where 'conversationUuid', '=', conversationMessage.conversationUuid
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'uuid', '=', conversationMessage.uuid
      .run()

      cknex().update 'conversation_messages_by_groupUuid_and_userUuid'
      .set _.omit conversationMessage, [
        'groupUuid', 'userUuid', 'timeBucket', 'uuid'
      ]
      .where 'groupUuid', '=', conversationMessage.groupUuid
      .andWhere 'userUuid', '=', conversationMessage.userUuid
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'uuid', '=', conversationMessage.uuid
      .run()

      cknex().update 'conversation_messages_by_uuid'
      .set _.omit conversationMessage, [
        'uuid'
      ]
      .where 'uuid', '=', conversationMessage.uuid
      .run()
    ]
    .then ->
      prepareFn?(conversationMessage) or conversationMessage
    .then (conversationMessage) =>
      unless isUpdate
        @streamCreate conversationMessage
      conversationMessage

  getAllByConversationUuid: (conversationUuid, options = {}) =>
    {limit, isStreamed, emit, socket, route, initialPostFn, postFn,
      minUuid, minUuid, reverse} = options

    minTime = if minUuid \
              then cknex.getTimeUuidFromString(minUuid).getDate()
              else undefined

    maxTime = if minUuid \
              then cknex.getTimeUuidFromString(minUuid).getDate()
              else undefined

    timeBucket = TimeService.getScaledTimeByTimeScale(
      'week', moment(minTime or maxTime)
    )

    get = (timeBucket) ->
      q = cknex().select '*'
      .from 'conversation_messages_by_conversationUuid'
      .where 'conversationUuid', '=', conversationUuid
      .andWhere 'timeBucket', '=', timeBucket

      if minUuid
        q.andWhere 'uuid', '>=', minUuid
        q.orderBy 'uuid', 'ASC'

      if minUuid
        q.andWhere 'uuid', '<', minUuid

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
        channelBy: 'conversationUuid'
        channelByUuid: conversationUuid
      }
    else
      initial
      .map (initialPostFn or _.uuidentity)

  unsubscribeByConversationUuid: (conversationUuid, {socket}) =>
    @unsubscribe {
      socket: socket
      channelBy: 'conversationUuid'
      channelByUuid: conversationUuid
    }

  getAllByGroupUuidAndUserUuidAndTimeBucket: (groupUuid, userUuid, timeBucket) ->
    cknex().select '*'
    .from 'conversation_messages_by_groupUuid_and_userUuid'
    .where 'groupUuid', '=', groupUuid
    .andWhere 'userUuid', '=', userUuid
    .andWhere 'timeBucket', '=', timeBucket
    .run()
    .map defaultConversationMessageOutput

  getByUuid: (uuid) ->
    cknex().select '*'
    .from 'conversation_messages_by_uuid'
    .where 'uuid', '=', uuid
    .run {isSingle: true}
    .then defaultConversationMessageOutput

  deleteByConversationMessage: (conversationMessage) =>
    Promise.all [
      cknex().delete()
      .from 'conversation_messages_by_conversationUuid'
      .where 'conversationUuid', '=', conversationMessage.conversationUuid
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'uuid', '=', conversationMessage.uuid
      .run()

      cknex().delete()
      .from 'conversation_messages_by_groupUuid_and_userUuid'
      .where 'groupUuid', '=', conversationMessage.groupUuid
      .andWhere 'userUuid', '=', conversationMessage.userUuid
      .andWhere 'timeBucket', '=', conversationMessage.timeBucket
      .andWhere 'uuid', '=', conversationMessage.uuid
      .run()

      cknex().delete()
      .from 'conversation_messages_by_uuid'
      .where 'uuid', '=', conversationMessage.uuid
      .run()
    ]
    .tap =>
      @streamDeleteByUuid conversationMessage.uuid, conversationMessage

  getLastByConversationUuid: (conversationUuid) =>
    @getAllByConversationUuid conversationUuid, {limit: 1}
    .then (messages) ->
      messages?[0]
    .then defaultConversationMessageOutput

  updateByUuid: (uuid, diff, {prepareFn}) =>
    @getByUuid uuid
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
      @streamUpdateByUuid uuid, conversationMessage

  deleteAllByGroupUuidAndUserUuid: (groupUuid, userUuid, {duration} = {}) =>
    duration ?= '7d' # TODO (doesn't actually do anything)

    del = (timeBucket) =>
      @getAllByGroupUuidAndUserUuidAndTimeBucket groupUuid, userUuid, timeBucket
      .map @deleteByConversationMessage

    del TimeService.getScaledTimeByTimeScale 'week'
    del TimeService.getScaledTimeByTimeScale(
      'week'
      moment().subtract(1, 'week')
    )

module.exports = new ConversationMessageModel()
