_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

ReviewBase = require './review_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class OvernightReview extends ReviewBase
  SCYLLA_TABLES: [
    {
      name: 'overnight_reviews_by_parentId'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        title: 'text'
        body: 'text'
        rating: 'int'
        rigType: 'text'
        rigLength: 'int'
        attachments: 'text' # json
      primaryKey:
        partitionKey: ['parentId']
        clusteringColumns: ['id']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'overnight_reviews_by_userId'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        title: 'text'
        body: 'text'
        rating: 'int'
        rigType: 'text'
        rigLength: 'int'
        attachments: 'text' # json
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: ['id']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'overnight_reviews_by_id'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        title: 'text'
        body: 'text'
        rating: 'int'
        rigType: 'text'
        rigLength: 'int'
        attachments: 'text' # json
      primaryKey:
        partitionKey: ['id']
    }
    {
      name: 'overnight_review_extras_by_id'
      keyspace: 'free_roam'
      ignoreUpsert: true
      fields:
        id: 'timeuuid' # review id
        userId: 'uuid'
        noise: 'text' # json {day: 3, night: 0}
        safety: 'int'
        cellSignal: 'text'
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'overnight_reviews'
      mappings:
        parentId: {type: 'text'}
        title: {type: 'text'}
        body: {type: 'text'}
        rating: {type: 'integer'}
        rigType: {type: 'text'}
        rigLength: {type: 'integer'}
    }
  ]

  defaultExtrasInput: (extras) ->
    unless extras?
      return null

    # transform existing data
    extras = _.defaults {
      noise: JSON.stringify extras.noise
      cellSignal: JSON.stringify extras.cellSignal
    }, extras

    # add data if non-existent
    _.defaults extras, {}

  defaultExtrasOutput: (extras) ->
    unless extras?
      return null

    jsonFields = [
      'noise', 'cellSignal'
    ]
    _.forEach jsonFields, (field) ->
      extras[field] = try
        JSON.parse extras[field]
      catch
        {}

    extras

  defaultInput: (overnight) ->
    unless overnight?
      return null

    # transform existing data
    overnight = _.defaults {
      attachments: JSON.stringify overnight.attachments
    }, overnight


    # add data if non-existent
    _.defaults overnight, {
      id: cknex.getTimeUuid()
      rating: 0
    }

  defaultOutput: (overnight) ->
    unless overnight?
      return null

    jsonFields = [
      'attachments'
    ]
    _.forEach jsonFields, (field) ->
      try
        overnight[field] = JSON.parse overnight[field]
      catch
        {}

    _.defaults {type: 'overnight'}, overnight


module.exports = new OvernightReview()
