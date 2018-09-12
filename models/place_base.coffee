_ = require 'lodash'
Promise = require 'bluebird'

cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class PlaceBase
  batchUpsert: (places) =>
    Promise.map places, (place) =>
      @upsert place

  upsert: (place) =>
    scyllaAmenity = @defaultInput place

    Promise.all [
      cknex().update @SCYLLA_TABLE_NAME
      .set _.omit scyllaAmenity, ['slug']
      .where 'slug', '=', scyllaAmenity.slug
      .run()

      @index place
    ]

  search: ({query}) =>
    elasticsearch.search {
      index: 'places'
      type: 'places'
      body:
        query: query
        from : 0
        size : 250
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        {slug: _id, name: _source.name, location: _source.location}

  index: (place) ->
    place.location = {lat: place.location[0], lon: place.location[1]}
    elasticsearch.index {
      index: @ELASTICSEARCH_INDEX_NAME
      type: @ELASTICSEARCH_INDEX_NAME
      id: place.slug
      body: _.pick place, _.keys @ELASTICSEARCH_INDICES[0].mappings
    }

  getBySlug: (slug) =>
    cknex().select '*'
    .from @SCYLLA_TABLE_NAME
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @SCYLLA_TABLE_NAME
    .limit limit
    .run()
    .map @defaultOutput
