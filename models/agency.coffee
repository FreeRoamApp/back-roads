Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

class Agency extends Base
  getScyllaTables: ->
    [
      {
        name: 'agencies_by_slug'
        keyspace: 'free_roam'
        fields:
          slug: 'text'
          name: 'text'
          bucket: {type: 'text', defaultFn: -> 'all'}
          type: {type: 'text', defaultFn: -> 'public'}
        primaryKey:
          partitionKey: ['bucket']
          clusteringColumns: ['slug']
      }
    ]

  getAll: ({limit} = {}) =>
    cknex().select '*'
    .from 'agencies_by_slug'
    .where 'bucket', '=', 'all'
    .run()
    .map @defaultOutput

  getBySlug: (slug) ->
    cknex().select '*'
    .from 'agencies_by_slug'
    .where 'bucket', '=', 'all'
    .andWhere 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

module.exports = new Agency()
