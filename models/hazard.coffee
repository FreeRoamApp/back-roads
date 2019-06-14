_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

# hazard, fire

class Hazard extends PlaceBase
  getScyllaTables: -> []
  getElasticSearchIndices: ->
    [
      {
        name: 'hazards'
        mappings:
          # common between all places
          name: {type: 'text'}
          details: {type: 'text'}
          slug: {type: 'keyword'}
          location: {type: 'geo_point'}
          subType: {type: 'keyword'}
          # end common

          data: {type: 'object'} # heightInches for hazard
      }
    ]

  getAllBySubType: (subType) ->
    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      size: 1000
      body:
        query:
          match: {subType}
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

  defaultOutput: (hazard) ->
    hazard = super hazard
    _.defaults {type: 'hazard'}, hazard

  defaultESInput: (row) ->
    row.id = "#{cknex.getTimeUuid()}"
    row

  defaultESOutput: (hazard) ->
    if hazard.subType is 'lowClearance'
      feet = Math.floor hazard.data.heightInches / 12
      inches = hazard.data.heightInches - feet * 12
      hazard.description = hazard.name
      hazard.name = if inches then "#{feet}' #{inches}\"" else "#{feet}'"
    else
      hazard.description = hazard.details
    hazard = _.defaults {
      type: 'hazard'
      icon: if hazard.subType is 'wildfire' then 'propane' else _.snakeCase hazard.subType
    }, _.pick hazard, ['name', 'description', 'location']

module.exports = new Hazard()
