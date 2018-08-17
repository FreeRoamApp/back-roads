_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
moment = require 'moment'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
TimeService = require '../services/time'
User = require './user'

# TODO: add groupUuid and thread_comments_by_groupUuid_by_userUuid to allow
# deleteAllByGroupUuidAndUserUuid. should also rename userUuid to userUuid

tables = [
  # sorting done in node

  # needs to have at least the keys that are partition keys from
  # other by_x tables (for updating all counters)
  {
    name: 'thread_comments_by_threadUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      threadUuid: 'uuid'
      parentType: 'text'
      parentUuid: 'uuid'
      userUuid: 'uuid'
      body: 'text'
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['threadUuid']
      clusteringColumns: [ 'parentType', 'parentUuid', 'uuid']
  }
  {
    name: 'thread_comments_counter_by_threadUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      threadUuid: 'uuid'
      parentType: 'text'
      parentUuid: 'uuid'
      upvotes: 'counter'
      downvotes: 'counter'
    primaryKey:
      partitionKey: ['threadUuid']
      clusteringColumns: [ 'parentType', 'parentUuid', 'uuid']
  }


  {
    name: 'thread_comments_by_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'uuid'
      threadUuid: 'uuid'
      parentType: 'text'
      parentUuid: 'uuid'
      userUuid: 'uuid'
      body: 'text'
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['userUuid', 'timeBucket']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  # do we even need this?
  {
    name: 'thread_comments_counter_by_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      userUuid: 'uuid'
      timeBucket: 'text'
      upvotes: 'counter'
      downvotes: 'counter'
    primaryKey:
      partitionKey: ['userUuid', 'timeBucket']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
]

ONE_MONTH_MS = 3600 * 24 * 30 * 1000

defaultThreadComment = (threadComment) ->
  unless threadComment?
    return null

  _.defaults threadComment, {
    uuid: cknex.getTimeUuid()
    timeBucket: TimeService.getScaledTimeByTimeScale 'month'
  }

class ThreadCommentModel
  SCYLLA_TABLES: tables

  upsert: (threadComment) ->
    threadComment = defaultThreadComment threadComment

    Promise.all [
      cknex().update 'thread_comments_by_userUuid'
      .set _.omit threadComment, [
        'userUuid', 'timeBucket', 'uuid'
      ]
      .where 'userUuid', '=', threadComment.userUuid
      .andWhere 'timeBucket', '=', threadComment.timeBucket
      .andWhere 'uuid', '=', threadComment.uuid
      .run()

      cknex().update 'thread_comments_by_threadUuid'
      .set _.omit threadComment, [
        'threadUuid', 'parentType', 'parentUuid', 'uuid'
      ]
      .where 'threadUuid', '=', threadComment.threadUuid
      .andWhere 'parentType', '=', threadComment.parentType
      .andWhere 'parentUuid', '=', threadComment.parentUuid
      .andWhere 'uuid', '=', threadComment.uuid
      .run()
    ]
    .then ->
      threadUuid = threadComment.threadUuid
      key = "#{CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID}:#{threadUuid}"
      CacheService.deleteByKey key
    .then ->
      threadComment

  voteByThreadComment: (threadComment, values) ->
    qByUserUuid = cknex().update 'thread_comments_counter_by_userUuid'
    _.forEach values, (value, key) ->
      qByUserUuid = qByUserUuid.increment key, value
    qByUserUuid = qByUserUuid.where 'userUuid', '=', threadComment.userUuid
    .andWhere 'timeBucket', '=', threadComment.timeBucket
    .andWhere 'uuid', '=', threadComment.uuid
    .run()

    qByThreadUuid = cknex().update 'thread_comments_counter_by_threadUuid'
    _.forEach values, (value, key) ->
      qByThreadUuid = qByThreadUuid.increment key, value
    qByThreadUuid = qByThreadUuid.where 'threadUuid', '=', threadComment.threadUuid
    .andWhere 'parentType', '=', threadComment.parentType
    .andWhere 'parentUuid', '=', threadComment.parentUuid
    .andWhere 'uuid', '=', threadComment.uuid
    .run()

    Promise.all [
      qByUserUuid
      qByThreadUuid
    ]

  getAllByThreadUuid: (threadUuid) ->
    # legacy. rm in mid feb 2018
    if threadUuid is 'b3d49e6f-3193-417e-a584-beb082196a2c' # cr-es
      threadUuid = '7a39b079-e6ce-11e7-9642-4b5962cd09d3'
    else if threadUuid is 'fcb35890-f40e-11e7-9af5-920aa1303bef' # bruno
      threadUuid = '90c06cb0-86ce-4ed6-9257-f36633db59c2'

    Promise.all [
      cknex().select '*'
      .from 'thread_comments_by_threadUuid'
      .where 'threadUuid', '=', threadUuid
      .run()

      cknex().select '*'
      .from 'thread_comments_counter_by_threadUuid'
      .where 'threadUuid', '=', threadUuid
      .run()
    ]
    .then ([allComments, voteCounts]) ->
      allComments = _.map allComments, (comment) ->
        voteCount = _.find voteCounts, {uuid: comment.uuid}
        voteCount ?= {upvotes: 0, downvotes: 0}
        _.merge comment, voteCount

  getCountByThreadUuid: (threadUuid) ->
    # legacy. rm in mid feb 2018
    if "#{threadUuid}" is 'b3d49e6f-3193-417e-a584-beb082196a2c' # cr-es
      threadUuid = '7a39b079-e6ce-11e7-9642-4b5962cd09d3'
    else if "#{threadUuid}" is 'fcb35890-f40e-11e7-9af5-920aa1303bef' # bruno
      threadUuid = '90c06cb0-86ce-4ed6-9257-f36633db59c2'

    cknex().select '*'
    .from 'thread_comments_by_threadUuid'
    .where 'threadUuid', '=', threadUuid
    .run()
    .then (threads) -> threads.length

  getAllByUserUuidAndTimeBucket: (userUuid, timeBucket) ->
    cknex().select '*'
    .from 'thread_comments_by_userUuid'
    .where 'userUuid', '=', userUuid
    .andWhere 'timeBucket', '=', timeBucket
    .run()

  deleteByThreadComment: (threadComment) ->
    Promise.all [
      cknex().delete()
      .from 'thread_comments_by_threadUuid'
      .where 'threadUuid', '=', threadComment.threadUuid
      .andWhere 'parentType', '=', threadComment.parentType
      .andWhere 'parentUuid', '=', threadComment.parentUuid
      .andWhere 'uuid', '=', threadComment.uuid
      .run()

      cknex().delete()
      .from 'thread_comments_counter_by_threadUuid'
      .where 'threadUuid', '=', threadComment.threadUuid
      .andWhere 'parentType', '=', threadComment.parentType
      .andWhere 'parentUuid', '=', threadComment.parentUuid
      .andWhere 'uuid', '=', threadComment.uuid
      .run()

      cknex().delete()
      .from 'thread_comments_by_userUuid'
      .where 'userUuid', '=', threadComment.userUuid
      .andWhere 'timeBucket', '=', threadComment.timeBucket
      .andWhere 'uuid', '=', threadComment.uuid
      .run()

      cknex().delete()
      .from 'thread_comments_counter_by_userUuid'
      .where 'userUuid', '=', threadComment.userUuid
      .andWhere 'timeBucket', '=', threadComment.timeBucket
      .andWhere 'uuid', '=', threadComment.uuid
      .run()
    ]


  deleteAllByUserUuid: (userUuid, {duration} = {}) =>
    del = (timeBucket) =>
      @getAllByUserUuidAndTimeBucket userUuid, timeBucket
      .map @deleteByThreadComment

    del TimeService.getScaledTimeByTimeScale 'month'
    del TimeService.getScaledTimeByTimeScale(
      'month'
      moment().subtract(1, 'month')
    )

  # would need another table to grab by id
  # getByUuid: (id) ->
  #   cknex().select '*'
  #   .from 'thread_comments_by_threadUuid'
  #   .where 'uuid', '=', uuid
  #   .run {isSingle: true}

module.exports = new ThreadCommentModel()
