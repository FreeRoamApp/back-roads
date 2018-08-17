_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
moment = require 'moment'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
TimeService = require '../services/time'
User = require './user'

# TODO: add groupId and thread_comments_by_groupId_by_userId to allow
# deleteAllByGroupIdAndUserId. should also rename userId to userId

tables = [
  # sorting done in node

  # needs to have at least the keys that are partition keys from
  # other by_x tables (for updating all counters)
  {
    name: 'thread_comments_by_threadId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      threadId: 'uuid'
      parentType: 'text'
      parentId: 'uuid'
      userId: 'uuid'
      body: 'text'
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['threadId']
      clusteringColumns: [ 'parentType', 'parentId', 'id']
  }
  {
    name: 'thread_comments_counter_by_threadId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      threadId: 'uuid'
      parentType: 'text'
      parentId: 'uuid'
      upvotes: 'counter'
      downvotes: 'counter'
    primaryKey:
      partitionKey: ['threadId']
      clusteringColumns: [ 'parentType', 'parentId', 'id']
  }


  {
    name: 'thread_comments_by_userId'
    keyspace: 'free_roam'
    fields:
      id: 'uuid'
      threadId: 'uuid'
      parentType: 'text'
      parentId: 'uuid'
      userId: 'uuid'
      body: 'text'
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['userId', 'timeBucket']
      clusteringColumns: ['id']
    withClusteringOrderBy: ['id', 'desc']
  }
  # do we even need this?
  {
    name: 'thread_comments_counter_by_userId'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      userId: 'uuid'
      timeBucket: 'text'
      upvotes: 'counter'
      downvotes: 'counter'
    primaryKey:
      partitionKey: ['userId', 'timeBucket']
      clusteringColumns: ['id']
    withClusteringOrderBy: ['id', 'desc']
  }
]

ONE_MONTH_MS = 3600 * 24 * 30 * 1000

defaultThreadComment = (threadComment) ->
  unless threadComment?
    return null

  _.defaults threadComment, {
    id: cknex.getTimeUuid()
    timeBucket: TimeService.getScaledTimeByTimeScale 'month'
  }

class ThreadCommentModel
  SCYLLA_TABLES: tables

  upsert: (threadComment) ->
    threadComment = defaultThreadComment threadComment

    Promise.all [
      cknex().update 'thread_comments_by_userId'
      .set _.omit threadComment, [
        'userId', 'timeBucket', 'id'
      ]
      .where 'userId', '=', threadComment.userId
      .andWhere 'timeBucket', '=', threadComment.timeBucket
      .andWhere 'id', '=', threadComment.id
      .run()

      cknex().update 'thread_comments_by_threadId'
      .set _.omit threadComment, [
        'threadId', 'parentType', 'parentId', 'id'
      ]
      .where 'threadId', '=', threadComment.threadId
      .andWhere 'parentType', '=', threadComment.parentType
      .andWhere 'parentId', '=', threadComment.parentId
      .andWhere 'id', '=', threadComment.id
      .run()
    ]
    .then ->
      threadId = threadComment.threadId
      key = "#{CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID}:#{threadId}"
      CacheService.deleteByKey key
    .then ->
      threadComment

  voteByThreadComment: (threadComment, values) ->
    qByUserId = cknex().update 'thread_comments_counter_by_userId'
    _.forEach values, (value, key) ->
      qByUserId = qByUserId.increment key, value
    qByUserId = qByUserId.where 'userId', '=', threadComment.userId
    .andWhere 'timeBucket', '=', threadComment.timeBucket
    .andWhere 'id', '=', threadComment.id
    .run()

    qByThreadId = cknex().update 'thread_comments_counter_by_threadId'
    _.forEach values, (value, key) ->
      qByThreadId = qByThreadId.increment key, value
    qByThreadId = qByThreadId.where 'threadId', '=', threadComment.threadId
    .andWhere 'parentType', '=', threadComment.parentType
    .andWhere 'parentId', '=', threadComment.parentId
    .andWhere 'id', '=', threadComment.id
    .run()

    Promise.all [
      qByUserId
      qByThreadId
    ]

  getAllByThreadId: (threadId) ->
    # legacy. rm in mid feb 2018
    if threadId is 'b3d49e6f-3193-417e-a584-beb082196a2c' # cr-es
      threadId = '7a39b079-e6ce-11e7-9642-4b5962cd09d3'
    else if threadId is 'fcb35890-f40e-11e7-9af5-920aa1303bef' # bruno
      threadId = '90c06cb0-86ce-4ed6-9257-f36633db59c2'

    Promise.all [
      cknex().select '*'
      .from 'thread_comments_by_threadId'
      .where 'threadId', '=', threadId
      .run()

      cknex().select '*'
      .from 'thread_comments_counter_by_threadId'
      .where 'threadId', '=', threadId
      .run()
    ]
    .then ([allComments, voteCounts]) ->
      allComments = _.map allComments, (comment) ->
        voteCount = _.find voteCounts, {id: comment.id}
        voteCount ?= {upvotes: 0, downvotes: 0}
        _.merge comment, voteCount

  getCountByThreadId: (threadId) ->
    # legacy. rm in mid feb 2018
    if "#{threadId}" is 'b3d49e6f-3193-417e-a584-beb082196a2c' # cr-es
      threadId = '7a39b079-e6ce-11e7-9642-4b5962cd09d3'
    else if "#{threadId}" is 'fcb35890-f40e-11e7-9af5-920aa1303bef' # bruno
      threadId = '90c06cb0-86ce-4ed6-9257-f36633db59c2'

    cknex().select '*'
    .from 'thread_comments_by_threadId'
    .where 'threadId', '=', threadId
    .run()
    .then (threads) -> threads.length

  getAllByUserIdAndTimeBucket: (userId, timeBucket) ->
    cknex().select '*'
    .from 'thread_comments_by_userId'
    .where 'userId', '=', userId
    .andWhere 'timeBucket', '=', timeBucket
    .run()

  deleteByThreadComment: (threadComment) ->
    Promise.all [
      cknex().delete()
      .from 'thread_comments_by_threadId'
      .where 'threadId', '=', threadComment.threadId
      .andWhere 'parentType', '=', threadComment.parentType
      .andWhere 'parentId', '=', threadComment.parentId
      .andWhere 'id', '=', threadComment.id
      .run()

      cknex().delete()
      .from 'thread_comments_counter_by_threadId'
      .where 'threadId', '=', threadComment.threadId
      .andWhere 'parentType', '=', threadComment.parentType
      .andWhere 'parentId', '=', threadComment.parentId
      .andWhere 'id', '=', threadComment.id
      .run()

      cknex().delete()
      .from 'thread_comments_by_userId'
      .where 'userId', '=', threadComment.userId
      .andWhere 'timeBucket', '=', threadComment.timeBucket
      .andWhere 'id', '=', threadComment.id
      .run()

      cknex().delete()
      .from 'thread_comments_counter_by_userId'
      .where 'userId', '=', threadComment.userId
      .andWhere 'timeBucket', '=', threadComment.timeBucket
      .andWhere 'id', '=', threadComment.id
      .run()
    ]


  deleteAllByUserId: (userId, {duration} = {}) =>
    del = (timeBucket) =>
      @getAllByUserIdAndTimeBucket userId, timeBucket
      .map @deleteByThreadComment

    del TimeService.getScaledTimeByTimeScale 'month'
    del TimeService.getScaledTimeByTimeScale(
      'month'
      moment().subtract(1, 'month')
    )

  # would need another table to grab by id
  # getById: (id) ->
  #   cknex().select '*'
  #   .from 'thread_comments_by_threadId'
  #   .where 'id', '=', id
  #   .run {isSingle: true}

module.exports = new ThreadCommentModel()
