_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

ReviewBase = require './review_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class OvernightReview extends ReviewBase
  type: 'overnightReview'

  getScyllaTables: ->
    [
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
    ].concat super

  getElasticSearchIndices: ->
    [
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

module.exports = new OvernightReview()
