Promise = require 'bluebird'
_ = require 'lodash'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class LocalMap extends Base
  getScyllaTables: ->
    [
      {
        name: 'local_maps_by_slug'
        keyspace: 'free_roam'
        fields:
          slug: 'text'
          type: {type: 'text', defaultFn: -> 'mvum'}
          name: 'text'
          url: 'text'
          downloadUrl: 'text'
          polygon: 'json'
          regionSlug: 'text'
          officeSlug: 'text'
          lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}
        primaryKey:
          partitionKey: ['slug']
      }
      {
        name: 'local_maps_by_type'
        keyspace: 'free_roam'
        fields:
          slug: 'text'
          type: {type: 'text', defaultFn: -> 'mvum'}
          name: 'text'
          url: 'text'
          downloadUrl: 'text'
          polygon: 'json'
          regionSlug: 'text'
          officeSlug: 'text'
          lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}
        primaryKey:
          partitionKey: ['type']
          clusteringColumns: ['slug']
      }
      {
        name: 'local_maps_by_region'
        keyspace: 'free_roam'
        fields:
          slug: 'text'
          type: {type: 'text', defaultFn: -> 'mvum'}
          name: 'text'
          url: 'text'
          downloadUrl: 'text'
          polygon: 'json'
          regionSlug: 'text'
          officeSlug: 'text'
          lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}
        primaryKey:
          partitionKey: ['regionSlug']
          clusteringColumns: ['type', 'slug']
      }
    ]

  getElasticSearchIndices: ->
    [
      {
        name: 'local_maps'
        mappings:
          name: {type: 'text'}
          slug: {type: 'keyword'}
          type: {type: 'keyword'}
          url: {type: 'text'}
          downloadUrl: {type: 'text'}
          polygon: {type: 'geo_shape'}
          regionSlug: {type: 'text'}
          officeSlug: {type: 'text'}
          lastUpdateTime: {type: 'date'}
      }
    ]

  getBySlug: (slug) =>
    cknex().select '*'
    .from 'local_maps_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getSlugFromRegionSlugAndCenter: (regionSlug, center) ->
    lat = Math.round(1000 * center[1]) / 1000
    lon = Math.round(1000 * center[0]) / 1000
    "#{regionSlug}-#{lat}-#{lon}"

  getAllByRegionSlug: (regionSlug) =>
    cknex().select '*'
    .from 'local_maps_by_region'
    .where 'regionSlug', '=', regionSlug
    .run()
    .map @defaultOutput

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

  getAllByLocationInPolygon: (location) =>
    @search {
      query:
        bool:
          filter:
            geo_shape:
              polygon:
                relation: 'intersects'
                shape:
                  type: 'point'
                  coordinates: [location.lon, location.lat]
    }

module.exports = new LocalMap()
