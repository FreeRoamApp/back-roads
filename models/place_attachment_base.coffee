_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

AttachmentBase = require './attachment_base'
cknex = require '../services/cknex'

module.exports = class PlaceAttachment extends AttachmentBase
  getScyllaTables: ->
    [
      {
        name: 'place_attachments_by_userId'
        keyspace: 'free_roam'
        fields:
          # common between all attachments
          id: 'timeuuid'
          parentId: 'uuid'
          parentType: 'text'
          userId: 'uuid'
          caption: 'text'
          tags: {type: 'set', subType: 'text'}
          type: 'text'
          prefix: 'text'
          aspectRatio: 'double'

          location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'place_attachments_counter_by_userId'
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
        name: 'place_attachments_counter_by_parentId'
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
    ].concat super

  defaultInput: (place) ->
    unless place?
      return null

    # transform existing data
    place = _.defaults {
    }, place


    # add data if non-existent
    _.defaults place, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (place) ->
    unless place?
      return null

    jsonFields = [
    ]
    _.forEach jsonFields, (field) ->
      try
        place[field] = JSON.parse place[field]
      catch
        {}

    _.defaults {@type}, place
