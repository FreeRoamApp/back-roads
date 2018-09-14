_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class PlaceBase extends Base
  search: ({query}) =>
    elasticsearch.search {
      index: @ELASTICSEARCH_INDICES[0].name
      type: @ELASTICSEARCH_INDICES[0].name
      body:
        query: query
        from : 0
        size : 250
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        {slug: _id, name: _source.name, location: _source.location}

  getBySlug: (slug) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .limit limit
    .run()
    .map @defaultOutput

  defaultESInput: (place) ->
    place.location = {lat: place.location[0], lon: place.location[1]}
    place