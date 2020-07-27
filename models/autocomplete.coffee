Promise = require 'bluebird'
_ = require 'lodash'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class Autocomplete extends Base
  getScyllaTables: -> []

  getElasticSearchIndices: ->
    [
      {
        name: 'autocompletes'
        mappings:
          text: {type: 'text'}
          locality: {type: 'keyword'}
          administrativeArea: {type: 'keyword'}
          location: {type: 'geo_point'}
      }
    ]

  search: ({query}) ->
    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      body:
        query: query
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

module.exports = new Autocomplete()
