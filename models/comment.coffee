_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
moment = require 'moment'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
TimeService = require '../services/time'
User = require './user'

# TODO: add groupId and comments_by_groupId_by_userId to allow
# deleteAllByGroupIdAndUserId. should also rename userId to userId

ONE_MONTH_MS = 3600 * 24 * 30 * 1000

class CommentModel extends Base
  getScyllaTables: ->
    [
      # sorting done in node

      # needs to have at least the keys that are partition keys from
      # other by_x tables (for updating all counters)
      {
        name: 'comments_by_topId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          topId: 'uuid'
          topType: 'text' # thread, campgroundReview, placeAttachment, ...
          parentType: 'text' # thread, comment
          parentId: 'uuid'
          userId: 'uuid'
          body: 'text'
          timeBucket: 'text'
        primaryKey:
          partitionKey: ['topId']
          clusteringColumns: [ 'parentType', 'parentId', 'id']
      }
      {
        name: 'comments_counter_by_topId'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          id: 'timeuuid'
          topId: 'uuid'
          parentType: 'text'
          parentId: 'uuid'
          upvotes: 'counter'
          downvotes: 'counter'
        primaryKey:
          partitionKey: ['topId']
          clusteringColumns: [ 'parentType', 'parentId', 'id']
      }
      {
        name: 'comments_by_userId'
        keyspace: 'free_roam'
        fields:
          id: 'uuid'
          topId: 'uuid'
          topType: 'text'
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
        name: 'comments_counter_by_userId'
        keyspace: 'free_roam'
        ignoreUpsert: true
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

  upsert: (comment) =>
    super comment
    .tap ->
      topId = comment.topId
      key = "#{CacheService.PREFIXES.COMMENTS_BY_TOP_ID}:#{topId}"
      CacheService.deleteByKey key

  voteByParent: (parent, values) ->
    qByUserId = cknex().update 'comments_counter_by_userId'
    _.forEach values, (value, key) ->
      qByUserId = qByUserId.increment key, value
    qByUserId = qByUserId.where 'userId', '=', parent.userId
    .andWhere 'timeBucket', '=', parent.timeBucket
    .andWhere 'id', '=', parent.id
    .run()

    qByTopId = cknex().update 'comments_counter_by_topId'
    _.forEach values, (value, key) ->
      qByTopId = qByTopId.increment key, value
    qByTopId = qByTopId.where 'topId', '=', parent.topId
    .andWhere 'parentType', '=', parent.parentType
    .andWhere 'parentId', '=', parent.parentId
    .andWhere 'id', '=', parent.id
    .run()

    Promise.all [
      qByUserId
      qByTopId
    ]

  getAllByTopId: (topId) ->
    Promise.all [
      cknex().select '*'
      .from 'comments_by_topId'
      .where 'topId', '=', topId
      .run()

      cknex().select '*'
      .from 'comments_counter_by_topId'
      .where 'topId', '=', topId
      .run()
    ]
    .then ([allComments, voteCounts]) ->
      allComments = _.map allComments, (comment) ->
        voteCount = _.find voteCounts, {id: comment.id}
        voteCount ?= {upvotes: 0, downvotes: 0}
        _.merge comment, voteCount

  getCountByTopId: (topId) ->
    cknex().select '*'
    .from 'comments_by_topId'
    .where 'topId', '=', topId
    .run()
    .then (tops) -> tops.length

  getAllByUserIdAndTimeBucket: (userId, timeBucket) ->
    cknex().select '*'
    .from 'comments_by_userId'
    .where 'userId', '=', userId
    .andWhere 'timeBucket', '=', timeBucket
    .run()

  deleteAllByUserId: (userId, {duration} = {}) =>
    del = (timeBucket) =>
      @getAllByUserIdAndTimeBucket userId, timeBucket
      .map @deleteByComment

    del TimeService.getScaledTimeByTimeScale 'month'
    del TimeService.getScaledTimeByTimeScale(
      'month'
      moment().subtract(1, 'month')
    )

  # would need another table to grab by id
  # getById: (id) ->
  #   cknex().select '*'
  #   .from 'comments_by_topId'
  #   .where 'id', '=', id
  #   .run {isSingle: true}

  defaultInput: (comment) ->
    unless comment?
      return null

    _.defaults comment, {
      id: cknex.getTimeUuid()
      timeBucket: TimeService.getScaledTimeByTimeScale 'month'
    }


module.exports = new CommentModel()
