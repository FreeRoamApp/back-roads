_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class SavedPlace extends PlaceBase
  SCYLLA_TABLES: []
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

  defaultInput: (savedPlace) ->
    unless savedPlace?
      return null

    # transform existing data
    savedPlace = _.defaults {
    }, savedPlace


    # add data if non-existent
    _.defaults savedPlace, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (savedPlace) ->
    unless savedPlace?
      return null

    jsonFields = []
    _.forEach jsonFields, (field) ->
      try
        savedPlace[field] = JSON.parse savedPlace[field]
      catch
        {}

    _.defaults {type: 'savedPlace'}, savedPlace

  defaultESOutput: (savedPlace) ->
    savedPlace = _.defaults {
      icon: savedPlace.icon
      type: 'saved'
    }, _.pick savedPlace, ['slug', 'name', 'location']

module.exports = new SavedPlace()
