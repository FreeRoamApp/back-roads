_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class PlaceBase extends Base
  search: ({query, sort, limit}, {outputFn} = {}) =>
    limit ?= 250
    outputFn ?= @defaultESOutput
    start = Date.now()

    if @ELASTICSEARCH_INDICES[0].mappings.ratingCount
      sort ?= [{'ratingCount': 'desc'}, '_score']

    elasticsearch.search {
      index: @ELASTICSEARCH_INDICES[0].name
      type: @ELASTICSEARCH_INDICES[0].name
      body:
        query:
          # random ordering so they don't clump on map
          function_score:
            query: query
            random_score:
              # static seed for everyone so points don't move around
              # when zooming
              seed: 'static'
            boost_mode: 'replace'
        sort: sort
        from: 0
        # it'd be nice to have these distributed more evently
        # grab ~2,000 and get random 250?
        # is this fast/efficient enough?
        size: limit
    }
    .then ({hits}) ->
      total = hits.total
      {
        total: total
        places: _.map hits.hits, ({_id, _source}) ->
          outputFn _.defaults _source, {id: _id}
      }

  searchNearby: (location, {distance, outputFn} = {}) =>
    distance ?= 2.5 # TODO: maybe less than 2.5 lat/lon points
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
