_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class PlaceBase extends Base
  search: ({query, sort, limit}, {outputFn} = {}) =>
    limit ?= 250
    outputFn ?= @defaultESOutput

    # console.log JSON.stringify query, null, 2

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      body:
        query:
          # random ordering so they don't clump on map
          function_score:
            query: query
            functions: _.filter [
              # prioritize places w/ reviews
              if @getElasticSearchIndices()[0].mappings.ratingCount
                {
                  filter:
                    range:
                      ratingCount:
                        gte: 1
                  weight: 50
                }
              # prioritize non-low clearances (eg fires)
              else if @getElasticSearchIndices()[0].name is 'hazards'
                {
                  filter:
                    bool:
                      must_not:
                        match:
                          subType: 'lowClearance'
                  weight: 50
                }
              {
                random_score:
                  # # static seed for everyone so points don't move around
                  # # when zooming
                  seed: 'static'
                weight: 50
              }
            ]
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

  searchNearby: (location, {limit, distance, outputFn} = {}) =>
    distance ?= 2.5 # TODO: maybe less than 2.5 lat/lon points
    @search {
      limit
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
    if @getScyllaTables()[0]
      cknex().select '*'
      .from @getScyllaTables()[0].name
      .where 'slug', '=', slug
      .run {isSingle: true}
      .then @defaultOutput
    else
      elasticsearch.search {
        index: @getElasticSearchIndices()[0].name
        type: @getElasticSearchIndices()[0].name
        size: 1
        body:
          query:
            match: {slug}
      }
      .then ({hits}) ->
        {_id, _source} = hits.hits?[0] or {}
        _.defaults _source, {id: _id}

  getById: (id) =>
    if @getScyllaTables()[1]
      cknex().select '*'
      .from @getScyllaTables()[1].name
      .where 'id', '=', id
      .run {isSingle: true}
      .then @defaultOutput
    else
      elasticsearch.search {
        index: @getElasticSearchIndices()[0].name
        type: @getElasticSearchIndices()[0].name
        size: 1
        body:
          query:
            ids:
              values: [id]
      }
      .then ({hits}) ->
        {_id, _source} = hits.hits?[0] or {}
        _.defaults _source, {id: _id}

  getAll: ({limit} = {}) =>
    limit ?= 30

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      size: limit
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}


  getAllByMinSlug: (minSlug, {limit} = {}) =>
    limit ?= 30

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      size: limit
      body:
        sort: [
          'slug'
        ]
        query:
          range:
            slug:
              gt: minSlug
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

  changeSlug: (place, newSlug) =>
    cknex().delete()
    .from @getScyllaTables()[0].name
    .where 'slug', '=', place.slug
    .run()
    .then =>
      @upsert _.defaults {slug: newSlug}, place

  defaultESInput: (place) ->
    if place.id
      place.id = "#{place.id}"
    place
