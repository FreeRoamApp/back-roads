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
          type: 'text' # image/video
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

  # type is already in-use (image/video...)
  # defaultOutput: (place) ->
  #   place = super place
  #   _.defaults {@type}, place
