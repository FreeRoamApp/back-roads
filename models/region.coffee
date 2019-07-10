Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

scyllaFields =
  slug: 'text'
  name: 'text'
  agencySlug: 'text'
  bucket: {type: 'text', defaultFn: -> 'all'}

class Region extends Base
  getScyllaTables: ->
    [
      {
        name: 'regions_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['bucket']
          clusteringColumns: ['slug']
      }
      {
        name: 'regions_by_agency'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['agencySlug']
          clusteringColumns: ['slug']
      }
    ]

  getAll: ({limit} = {}) =>
    cknex().select '*'
    .from 'regions_by_slug'
    .where 'bucket', '=', 'all'
    .run()
    .map @defaultOutput

  getAllByAgencySlug: (agencySlug, {limit} = {}) =>
    cknex().select '*'
    .from 'regions_by_agency'
    .where 'agencySlug', '=', agencySlug
    .run()
    .map @defaultOutput

  getBySlug: (slug) ->
    cknex().select '*'
    .from 'regions_by_slug'
    .where 'bucket', '=', 'all'
    .andWhere 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

module.exports = new Region()
