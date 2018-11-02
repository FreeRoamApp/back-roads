_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

AttachmentBase = require './attachment_base'
cknex = require '../services/cknex'

class ReviewlessCampgroundAttachment extends AttachmentBase
  SCYLLA_TABLES: [
    {
      name: 'reviewless_campground_attachments_by_parentId'
      keyspace: 'free_roam'
      fields:
        # common between all attachments
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        caption: 'text'
        tags: {type: 'set', subType: 'text'}
        type: 'text'
        prefix: 'text'
        aspectRatio: 'double'

        location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
      primaryKey:
        partitionKey: ['parentId']
        clusteringColumns: ['id']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'reviewless_campground_attachments_by_id'
      keyspace: 'free_roam'
      fields:
        # common between all attachments
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        caption: 'text'
        tags: {type: 'set', subType: 'text'}
        type: 'text'
        prefix: 'text'
        aspectRatio: 'double'

        location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
      primaryKey:
        partitionKey: ['id']
    }
    {
      name: 'reviewless_campground_attachments_counter_by_id'
      ignoreUpsert: true
      fields:
        id: 'timeuuid'
        upvotes: 'counter'
        downvotes: 'counter'
      primaryKey:
        partitionKey: ['id']
        clusteringColumns: null
    }
  ]

  defaultInput: (reviewlessCampgroundAttachment) ->
    unless reviewlessCampgroundAttachment?
      return null

    # transform existing data
    reviewlessCampgroundAttachment = _.defaults {
    }, reviewlessCampgroundAttachment


    # add data if non-existent
    _.defaults reviewlessCampgroundAttachment, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (reviewlessCampgroundAttachment) ->
    unless reviewlessCampgroundAttachment?
      return null

    jsonFields = [
    ]
    _.forEach jsonFields, (field) ->
      try
        reviewlessCampgroundAttachment[field] = JSON.parse(
          reviewlessCampgroundAttachment[field]
        )
      catch
        {}

    _.defaults {
      type: 'reviewlessCampgroundAttachment'
    }, reviewlessCampgroundAttachment


module.exports = new ReviewlessCampgroundAttachment()
