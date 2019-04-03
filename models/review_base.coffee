_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class ReviewBase extends Base
  getScyllaTables: ->
    [
      {
        name: 'reviews_by_userId'
        keyspace: 'free_roam'
        fields:
          # common between all reviews
          id: 'timeuuid'
          parentId: 'uuid'
          parentType: 'text'
          userId: 'uuid'
          title: 'text'
          body: 'text'
          rating: 'int'
          attachments: 'text' # json
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'reviews_counter_by_userId'
        ignoreUpsert: true
        fields:
          id: 'uuid'
          userId: 'uuid'
          upvotes: 'counter'
          downvotes: 'counter'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
      }
      {
        name: 'reviews_counter_by_parentId'
        ignoreUpsert: true
        fields:
          id: 'uuid'
          parentId: 'uuid'
          upvotes: 'counter'
          downvotes: 'counter'
        primaryKey:
          partitionKey: ['parentId']
          clusteringColumns: ['id']
      }
    ]

  getCounterById: (id) ->
    cknex().select '*'
    .from 'reviews_counter_by_parentId'
    .where 'id', '=', id
    .run {isSingle: true}

  voteByParent: (parent, values, userId) ->
    qByUserId = cknex().update 'reviews_counter_by_userId'
    _.forEach values, (value, key) ->
      qByUserId = qByUserId.increment key, value
    qByUserId = qByUserId.where 'userId', '=', userId
    .andWhere 'id', '=', parent.id
    .run()

    qByTopId = cknex().update 'reviews_counter_by_parentId'
    _.forEach values, (value, key) ->
      qByTopId = qByTopId.increment key, value
    qByTopId = qByTopId.where 'parentId', '=', parent.topId
    .andWhere 'id', '=', parent.id
    .run()

    Promise.all [
      qByUserId
      qByTopId
    ]

  search: ({query}) =>
    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      body:
        query: query
        from : 0
        size : 250
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        {slug: _id, title: _source.title, details: _source.details}

  getById: (id) =>
    cknex().select '*'
    .from @getScyllaTables()[1].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getAllByParentId: (parentId) ->
    Promise.all [
      cknex().select '*'
      .from @getScyllaTables()[0].name
      .where 'parentId', '=', parentId
      .run()
      .map @defaultOutput

      cknex().select '*'
      .from 'reviews_counter_by_parentId'
      .where 'parentId', '=', parentId
      .run()
    ]
    .then ([allReviews, voteCounts]) ->
      allReviews = _.map allReviews, (review) ->
        voteCount = _.find voteCounts, {id: review.id}
        voteCount ?= {upvotes: 0, downvotes: 0}
        review.upvotes = voteCount.upvotes
        review.downvotes = voteCount.downvotes
        review
        # _.merge review, voteCount # messages with timeuuids

  getAllByUserId: (userId) ->
    Promise.all [
      cknex().select '*'
      .from 'reviews_by_userId'
      .where 'userId', '=', userId
      .run()
      .map @defaultOutput

      cknex().select '*'
      .from 'reviews_counter_by_userId'
      .where 'userId', '=', userId
      .run()
    ]
    .then ([allReviews, voteCounts]) ->
      allReviews = _.map allReviews, (review) ->
        voteCount = _.find voteCounts, {id: review.id}
        voteCount ?= {upvotes: 0, downvotes: 0}
        review.upvotes = voteCount.upvotes
        review.downvotes = voteCount.downvotes
        review
        # _.merge review, voteCount # messages with timeuuids

  getAll: ({limit} = {}) =>
    limit ?= 30

    Promise.resolve elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      size: limit
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

    # cknex().select '*'
    # .from @getScyllaTables()[0].name
    # .limit limit
    # .run()
    # .map @defaultOutput

  deleteByRow: (row) ->
    super(row).then ->
      cknex().delete()
      .from 'reviews_counter_by_parentId'
      .where 'parentId', '=', row.parentId
      .where 'id', '=', row.id
      .run()

  getExtrasById: (id) =>
    cknex().select '*'
    .from @getScyllaTables()[2].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultExtrasOutput

  upsertExtras: (extras) =>
    extras = @defaultExtrasInput extras
    cknex().update @getScyllaTables()[2].name
    .set _.omit extras, ['id']
    .where 'id', '=', extras.id
    .run()

  deleteExtrasById: (id) =>
    cknex().delete()
    .from @getScyllaTables()[2].name
    .where 'id', '=', id
    .run()

  defaultInput: (place) ->
    unless place?
      return null

    # transform existing data
    place = _.defaults {
      attachments: JSON.stringify place.attachments
    }, place


    # add data if non-existent
    _.defaults place, {
      id: cknex.getTimeUuid()
      rating: 0
    }

  defaultOutput: (place) =>
    unless place?
      return null

    jsonFields = [
      'attachments'
    ]
    _.forEach jsonFields, (field) ->
      try
        place[field] = JSON.parse place[field]
      catch
        {}

    _.defaults {type: @type}, place
