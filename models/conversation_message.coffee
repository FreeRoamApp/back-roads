_ = require 'lodash'
Promise = require 'bluebird'
moment = require 'moment'
uuid = require 'node-uuid'

StreamService = require '../services/stream'
TimeService = require '../services/time'
CacheService = require '../services/cache'
cknex = require '../services/cknex'
Base = require './base'
config = require '../config'

class ConversationMessageModel extends Base
  getScyllaTables: ->
    [
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

  constructor: ->
    @streamChannelKey = 'conversation_message'
    @streamChannelsBy = ['conversationId']

  getAllByConversationId: (conversationId, options = {}) =>
    {limit, isStreamed, emit, socket, route, initialPostFn, postFn,
      minId, maxId, reverse} = options

    minTime = if minId \
              then cknex.getTimeUuidFromString(minId).getDate()
              else undefined

    maxTime = if maxId \
              then cknex.getTimeUuidFromString(maxId).getDate()
              else undefined

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

    getAll = (time, count = 0, depth = 0) ->
      if depth > 5
        return Promise.resolve []

      timeBucket = TimeService.getScaledTimeByTimeScale(
        'week', time
      )
      get timeBucket
      .then (results) ->
        count += results.length
        # if not enough results, check previous time buckets
        if limit and count < limit
          lastWeekTime = time.subtract 1, 'week'
          getAll lastWeekTime, count, depth + 1
          .then (olderMessages) ->
            _.filter (results or []).concat olderMessages
        else
          results

    initial = getAll moment(minTime or maxTime)
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

  getAllByGroupIdAndUserIdAndTimeBucket: (groupId, userId, timeBucket) =>
    cknex().select '*'
    .from 'conversation_messages_by_groupId_and_userId'
    .where 'groupId', '=', groupId
    .andWhere 'userId', '=', userId
    .andWhere 'timeBucket', '=', timeBucket
    .run()
    .map @defaultOutput

  getById: (id) =>
    cknex().select '*'
    .from 'conversation_messages_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  # TODO: super() (deleteByRow)
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
    .then @defaultOutput

  updateById: (id, diff, {prepareFn}) =>
    @getById id
    .then @defaultOutput
    .then (conversationMessage) =>
      updatedMessage = _.defaults(diff, conversationMessage)
      updatedMessage.lastUpdateTime = new Date()

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

  defaultInput: (conversationMessage) ->
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

  defaultOutput: (conversationMessage) ->
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

module.exports = new ConversationMessageModel()
