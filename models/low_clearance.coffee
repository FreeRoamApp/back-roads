_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class LowClearance extends PlaceBase
  getScyllaTables: -> []
  getElasticSearchIndices: ->
    [
      {
        name: 'low_clearances'
        mappings:
          # common between all places
          name: {type: 'text'}
          location: {type: 'geo_point'}
          # end common
          heightInches: {type: 'integer'}
      }
    ]

  defaultOutput: (lowClearance) ->
    lowClearance = super lowClearance
    _.defaults {type: 'lowClearance'}, lowClearance

  defaultESOutput: (lowClearance) ->
    feet = Math.floor lowClearance.heightInches / 12
    inches = lowClearance.heightInches - feet * 12
    lowClearance = _.defaults {
      name: if inches then "#{feet}' #{inches}\"" else "#{feet}'"
      description: lowClearance.name
      type: 'lowClearance'
      icon: 'low_clearance'
    }, _.pick lowClearance, ['name', 'location']

module.exports = new LowClearance()
