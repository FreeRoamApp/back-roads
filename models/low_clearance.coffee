_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class LowClearance extends PlaceBase
  SCYLLA_TABLES: []
  ELASTICSEARCH_INDICES: [
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

  defaultInput: (lowClearance) ->
    unless lowClearance?
      return null

    # transform existing data
    lowClearance = _.defaults {
    }, lowClearance


    # add data if non-existent
    _.defaults lowClearance, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (lowClearance) ->
    unless lowClearance?
      return null

    jsonFields = []
    _.forEach jsonFields, (field) ->
      try
        lowClearance[field] = JSON.parse lowClearance[field]
      catch
        {}

    _.defaults {type: 'lowClearance'}, lowClearance

  defaultESOutput: (lowClearance) ->
    feet = Math.floor lowClearance.heightInches / 12
    inches = lowClearance.heightInches - feet * 12
    lowClearance = _.defaults {
      name: if inches then "#{feet}' #{inches}\"" else "#{feet}'"
      description: lowClearance.name
      icon: 'low_clearance'
    }, _.pick lowClearance, ['name', 'icon', 'location']

module.exports = new LowClearance()
