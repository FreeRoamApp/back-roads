_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class PlaceBase extends Base
  search: ({query, sort}, {outputFn} = {}) =>
    outputFn ?= @defaultESOutput
    elasticsearch.search {
      index: @ELASTICSEARCH_INDICES[0].name
      type: @ELASTICSEARCH_INDICES[0].name
      body:
        query: query
        sort: sort
        from: 0
        size: 250
    }
    .then ({hits}) ->
      # console.log 'got', hits
      _.map hits.hits, ({_id, _source}) ->
        outputFn _.defaults _source, {id: _id}

  searchNearby: (location, {distance, outputFn} = {}) =>
    distance = 2.5 # TODO: maybe less than 2.5 lat/lon points
    @search {
      query:
        bool:
          filter: [
            {
              geo_bounding_box:
                location:
                  top_left:
                    lat: location.lat + distance
                    lon: location.lon - distance
                  bottom_right:
                    lat: location.lat - distance
                    lon: location.lon + distance
            }
          ]
      sort: [
        _geo_distance:
          location:
            lat: location.lat
            lon: location.lon
          order: 'asc'
          unit: 'km'
          distance_type: 'plane'
      ]
    }, {outputFn}

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
    place
