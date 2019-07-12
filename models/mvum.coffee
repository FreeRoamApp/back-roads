Promise = require 'bluebird'
_ = require 'lodash'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class Mvum extends Base
  getScyllaTables: ->
    [
      {
        name: 'mvums_by_slug'
        keyspace: 'free_roam'
        fields:
          slug: 'text'
          name: 'text'
          url: 'text'
          polygon: 'json'
          regionSlug: 'text'
          officeSlug: 'text'
          lastUpdateTime: 'timestamp'
        primaryKey:
          partitionKey: ['slug']
      }
      {
        name: 'mvums_by_region'
        keyspace: 'free_roam'
        fields:
          slug: 'text'
          name: 'text'
          url: 'text'
          polygon: 'json'
          regionSlug: 'text'
          officeSlug: 'text'
          lastUpdateTime: 'timestamp'
        primaryKey:
          partitionKey: ['regionSlug']
          clusteringColumns: ['slug']
      }
    ]

  getElasticSearchIndices: ->
    [
      {
        name: 'mvums'
        mappings:
          name: {type: 'text'}
          url: {type: 'text'}
          polygon: {type: 'geo_shape'}
          regionSlug: {type: 'text'}
          officeSlug: {type: 'text'}
          lastUpdateTime: {type: 'date'}
      }
    ]

  getBySlug: (slug) =>
    cknex().select '*'
    .from 'mvums_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getSlugFromRegionSlugAndCenter: (regionSlug, center) ->
    lat = Math.round(1000 * center[1]) / 1000
    lon = Math.round(1000 * center[0]) / 1000
    "#{regionSlug}-#{lat}-#{lon}"

  getAllByRegionSlug: (regionSlug) =>
    cknex().select '*'
    .from 'mvums_by_region'
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

module.exports = new Mvum()

# module.exports.search {
#   query:
#     bool:
#       filter:
#         geo_shape:
#           polygon:
#             relation: 'intersects'
#             shape:
#               type: 'point'
#               coordinates: [-121.68206161929695, 44.54955990120351]
# }
# .then (res) ->
#   console.log res
