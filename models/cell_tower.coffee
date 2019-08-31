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
  getScyllaTables: -> []
  getElasticSearchIndices: ->
    [
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

  defaultOutput: (cellTower) ->
    cellTower = super cellTower

    cellTower = _.defaults {type: 'cellTower'}, cellTower

  defaultESOutput: (cellTower) ->
    cellTower = _.defaults {
      name: "#{carriers[cellTower.carrier]} #{cellTower.tech}"
      type: 'cellTower'
    }, _.pick cellTower, ['slug', 'name', 'location', 'carrier']

module.exports = new CellTower()
