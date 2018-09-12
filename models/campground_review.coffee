_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

ReviewBase = require './review_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
return
# main should be like yelp, kayak, etc...? search page. when typing, prepopulate: boondocking, rv park, walmart
# TODO: campgrounds_translations_by_slug_and_language
# override english values

class CampgroundReview extends ReviewBase
  SCYLLA_TABLES: [
    {
      name: 'campground_reviews_by_placeId'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        placeId: 'uuid'
        title: 'text'
        details: 'text' # wikipedia style info. can be stylized with markdown
        rating: 'int'
        images: 'text' # json
        videos: 'text' # json
      primaryKey:
        partitionKey: ['placeId']
        clusteringColumns: ['id']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'campground_reviews_by_userId'
      keyspace: 'free_roam'
      fields:
        # common between all reviews
        id: 'timeuuid'
        placeId: 'uuid'
        title: 'text'
        details: 'text' # wikipedia style info. can be stylized with markdown
        rating: 'int'
        images: 'text' # json
        videos: 'text' # json
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
        placeId: 'uuid'
        title: 'text'
        details: 'text' # wikipedia style info. can be stylized with markdown
        rating: 'int'
        images: 'text' # json
        videos: 'text' # json
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: ELASTICSEARCH_INDEX_NAME
      mappings:
        placeId: {type: 'text'}
        title: {type: 'text'}
        details: {type: 'text'}
        rating: {type: 'integer'}
    }
  ]

  defaultInput: (campground) ->
    unless campground?
      return null

    # transform existing data
    campground = _.defaults {
      siteCount: JSON.stringify campground.siteCount
      crowds: JSON.stringify campground.crowds
      fullness: JSON.stringify campground.fullness
      noise: JSON.stringify campground.noise
      cellSignal: JSON.stringify campground.cellSignal
      restrooms: JSON.stringify campground.restrooms
      videos: JSON.stringify campground.videos
      address: JSON.stringify campground.address
    }, campground


    # add data if non-existent
    _.defaults campground, {
      rating: 0
    }

  defaultOutput: (campground) ->
    unless campground?
      return null

    jsonFields = [
      'siteCount', 'crowds', 'fullness', 'noise', 'cellSignal',
      'restrooms', 'videos', 'address'
    ]
    _.forEach jsonFields, (field) ->
      try
        campground[field] = JSON.parse campground[field]
      catch
        {}

    _.defaults {type: 'campground'}, campground


module.exports = new CampgroundReview()
