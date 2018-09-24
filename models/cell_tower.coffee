_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

carriers =
  att: 'AT&T'
  verizon: 'Verizon'
  tmobile: 'T-Mobile'
  sprint: 'Sprint'

class CellTower extends PlaceBase
  SCYLLA_TABLES: [
    {
      name: 'cell_towers_by_slug'
      keyspace: 'free_roam'
      fields:
        # common between all places
        slug: 'text'
        id: 'timeuuid'
        location: {type: 'set', subType: 'double'} # coordinates
        # end common

        carrier: 'text'
        tech: 'text'

      primaryKey:
        partitionKey: ['slug']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'cell_towers'
      mappings:
        # common between all places
        location: {type: 'geo_point'}
        # end common
        carrier: {type: 'text'}
        tech: {type: 'text'}
    }
  ]

  defaultInput: (cellTower) ->
    unless cellTower?
      return null

    # transform existing data
    cellTower = _.defaults {
    }, cellTower


    # add data if non-existent
    _.defaults cellTower, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (cellTower) ->
    unless cellTower?
      return null

    jsonFields = []
    _.forEach jsonFields, (field) ->
      try
        cellTower[field] = JSON.parse cellTower[field]
      catch
        {}

    _.defaults {type: 'cellTower'}, cellTower

  defaultESOutput: (cellTower) ->
    cellTower = _.defaults {
      name: "#{carriers[cellTower.carrier]} #{cellTower.tech}"
      icon: cellTower.carrier
    }, _.pick cellTower, ['slug', 'name', 'icon', 'location']

module.exports = new CellTower()
