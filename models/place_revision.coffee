Base = require './base'

class PlaceRevision extends Base
  type: 'placeRevision'

  getScyllaTables: ->
    [
      {
        name: 'place_revisions_by_placeId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          placeId: 'timeuuid'
          userId: 'timeuuid'
          action: 'text' # insert, update, delete
          diff: 'json'
          current: 'json'
        primaryKey:
          partitionKey: ['placeId']
          clusteringColumns: ['id']
      }
    ]

  getById: ->
    cknex().select '*'
    .from 'place_revisions_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput


module.exports = new PlaceRevision()
