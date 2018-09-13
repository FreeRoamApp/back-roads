_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

ReviewBase = require './review_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class CampgroundReview extends ReviewBase
  SCYLLA_TABLES: [
    {
      name: 'campground_reviews_by_parentId'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        title: 'text'
        body: 'text'
        rating: 'int'
        attachments: 'text' # json
      primaryKey:
        partitionKey: ['parentId']
        clusteringColumns: ['id']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'campground_reviews_by_userId'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        parentId: 'uuid'
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
      name: 'campground_reviews_by_id'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        title: 'text'
        body: 'text'
        rating: 'int'
        attachments: 'text' # json
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'campground_reviews'
      mappings:
        parentId: {type: 'text'}
        title: {type: 'text'}
        body: {type: 'text'}
        rating: {type: 'integer'}
    }
  ]

  defaultInput: (campground) ->
    unless campground?
      return null

    # transform existing data
    campground = _.defaults {
      attachments: JSON.stringify campground.attachments
    }, campground


    # add data if non-existent
    _.defaults campground, {
      id: cknex.getTimeUuid()
      rating: 0
    }

  defaultOutput: (campground) ->
    unless campground?
      return null

    jsonFields = [
      'attachments'
    ]
    _.forEach jsonFields, (field) ->
      try
        campground[field] = JSON.parse campground[field]
      catch
        {}

    _.defaults {type: 'campground'}, campground


module.exports = new CampgroundReview()
