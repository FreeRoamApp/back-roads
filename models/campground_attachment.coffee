PlaceAttachmentBase = require './place_attachment_base'

class CampgroundAttachment extends PlaceAttachmentBase
  type: 'campgroundAttachment'

  getScyllaTables: ->
    [
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
          prefix: 'text'
          aspectRatio: 'double'

          location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
        primaryKey:
          partitionKey: ['parentId']
          clusteringColumns: ['id']
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
          prefix: 'text'
          aspectRatio: 'double'

          location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
        primaryKey:
          partitionKey: ['id']
      }
    ].concat super

module.exports = new CampgroundAttachment()
