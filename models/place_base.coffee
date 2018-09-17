_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class PlaceBase extends Base
  search: ({query, sort}) =>
    elasticsearch.search {
      index: @ELASTICSEARCH_INDICES[0].name
      type: @ELASTICSEARCH_INDICES[0].name
      body:
        query: query
        sort: sort
        from: 0
        size: 250
    }
    .then ({hits}) =>
      # console.log 'got', hits
      _.map hits.hits, ({_id, _source}) =>
        @defaultESOutput _.defaults _source, {id: _id}

  getBySlug: (slug) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getById: (id) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[1].name
    .where 'id', '=', id
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
    if place.id
      place.id = "#{place.id}"
    if place.location
      place.location = {lat: place.location[0], lon: place.location[1]}
    place
