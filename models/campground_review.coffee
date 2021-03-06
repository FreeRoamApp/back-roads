_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

ReviewBase = require './review_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

scyllaFields =
  # common between all reviews
  id: 'timeuuid'
  parentId: 'uuid'
  userId: 'uuid'
  title: 'text'
  body: 'text'
  rating: 'int'
  rigType: 'text'
  rigLength: 'int'
  attachments: 'json' # json

class CampgroundReview extends ReviewBase
  type: 'campgroundReview'

  getScyllaTables: ->
    [
      {
        name: 'campground_reviews_by_parentId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['parentId']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'campground_reviews_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
      {
        name: 'campground_review_extras_by_id'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          id: 'timeuuid' # review id
          userId: 'uuid'
          roadDifficulty: 'int'
          crowds: 'json' # json {winter: 2, spring: 5, summer: 10, fall: 5}
          fullness: 'json' # json {winter: 2, spring: 5, summer: 10, fall: 5}
          noise: 'json' # json {day: 3, night: 0}
          shade: 'int'
          cleanliness: 'int'
          safety: 'int'
          cellSignal: 'json'
          pricePaid: 'double'
        primaryKey:
          partitionKey: ['id']
      }
    ].concat super

  getElasticSearchIndices: -> [
    {
      name: 'campground_reviews'
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
      crowds: JSON.stringify extras.crowds
      fullness: JSON.stringify extras.fullness
      noise: JSON.stringify extras.noise
      cellSignal: JSON.stringify extras.cellSignal
    }, extras

    # add data if non-existent
    _.defaults extras, {}

  defaultExtrasOutput: (extras) ->
    unless extras?
      return null

    jsonFields = [
      'crowds', 'fullness', 'noise', 'cellSignal'
    ]
    _.forEach jsonFields, (field) ->
      extras[field] = try
        JSON.parse extras[field]
      catch
        {}

    extras


module.exports = new CampgroundReview()
