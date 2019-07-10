Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

scyllaFields =
  slug: 'text'
  agencySlug: 'text'
  regionSlug: 'text'
  name: 'text'
  bucket: {type: 'text', defaultFn: -> 'all'}

class Office extends Base
  getScyllaTables: ->
    [
      {
        name: 'offices_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['bucket']
          clusteringColumns: ['slug']
      }
      {
        name: 'offices_by_agency_and_region'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['agencySlug']
          clusteringColumns: ['regionSlug', 'slug']
      }
    ]

  getAll: ({limit} = {}) =>
    cknex().select '*'
    .from 'offices_by_slug'
    .where 'bucket', '=', 'all'
    .run()
    .map @defaultOutput

  getAllByAgencySlugAndRegionSlug: (agencySlug, regionSlug, {limit} = {}) =>
    cknex().select '*'
    .from 'offices_by_agency_and_region'
    .where 'agencySlug', '=', agencySlug
    .andWhere 'regionSlug', '=', regionSlug
    .run()
    .map @defaultOutput

  getBySlug: (slug) ->
    cknex().select '*'
    .from 'offices_by_slug'
    .where 'bucket', '=', 'all'
    .andWhere 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

module.exports = new Office()
