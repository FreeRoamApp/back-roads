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
      type: 'cellTower'
    }, _.pick cellTower, ['slug', 'name', 'location']

module.exports = new CellTower()
