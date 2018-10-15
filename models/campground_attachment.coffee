_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

AttachmentBase = require './attachment_base'
cknex = require '../services/cknex'

class CampgroundAttachment extends AttachmentBase
  SCYLLA_TABLES: [
    {
      name: 'campground_attachments_by_parentId'
      keyspace: 'free_roam'
      fields:
        # common between all attachments
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        caption: 'text'
        tags: {type: 'set', subType: 'text'}
        type: 'text'
        aspectRatio: 'double'
        src: 'text'
        smallSrc: 'text'
        largeSrc: 'text'

        location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
      primaryKey:
        partitionKey: ['parentId']
        clusteringColumns: ['id', 'src']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'campground_attachments_by_id'
      keyspace: 'free_roam'
      fields:
        # common between all attachments
        id: 'timeuuid'
        parentId: 'uuid'
        userId: 'uuid'
        caption: 'text'
        tags: {type: 'set', subType: 'text'}
        type: 'text'
        aspectRatio: 'double'
        src: 'text'
        smallSrc: 'text'
        largeSrc: 'text'

        location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
      primaryKey:
        partitionKey: ['id']
        clusteringColumns: ['src']
    }
    {
      name: 'campground_attachments_counter_by_id'
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

  defaultInput: (campground) ->
    unless campground?
      return null

    # transform existing data
    campground = _.defaults {
    }, campground


    # add data if non-existent
    _.defaults campground, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (campground) ->
    unless campground?
      return null

    jsonFields = [
    ]
    _.forEach jsonFields, (field) ->
      try
        campground[field] = JSON.parse campground[field]
      catch
        {}

    _.defaults {type: 'campground'}, campground


module.exports = new CampgroundAttachment()
