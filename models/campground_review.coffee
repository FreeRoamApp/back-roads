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
    {
      name: 'campground_review_extras_by_id'
      keyspace: 'free_roam'
      ignoreUpsert: true
      fields:
        id: 'timeuuid' # review id
        userId: 'uuid'
        roadDifficulty: 'int'
        crowds: 'text' # json {winter: 2, spring: 5, summer: 10, fall: 5}
        fullness: 'text' # json {winter: 2, spring: 5, summer: 10, fall: 5}
        noise: 'text' # json {day: 3, night: 0}
        shade: 'int'
        cleanliness: 'int'
        safety: 'int'
        cellSignal: 'text'
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
