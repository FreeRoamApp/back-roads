_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

AttachmentBase = require './attachment_base'
cknex = require '../services/cknex'

class OvernightAttachment extends AttachmentBase
  SCYLLA_TABLES: [
    {
      name: 'overnight_attachments_by_parentId'
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
      primaryKey:
        partitionKey: ['parentId']
        clusteringColumns: ['id']
      withClusteringOrderBy: ['id', 'desc']
    }
    {
      name: 'overnight_attachments_by_id'
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
      primaryKey:
        partitionKey: ['id']
    }
    {
      name: 'overnight_attachments_counter_by_id'
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

  defaultInput: (overnight) ->
    unless overnight?
      return null

    # transform existing data
    overnight = _.defaults {
    }, overnight


    # add data if non-existent
    _.defaults overnight, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (overnight) ->
    unless overnight?
      return null

    jsonFields = [
    ]
    _.forEach jsonFields, (field) ->
      try
        overnight[field] = JSON.parse overnight[field]
      catch
        {}

    _.defaults {type: 'overnight'}, overnight


module.exports = new OvernightAttachment()
