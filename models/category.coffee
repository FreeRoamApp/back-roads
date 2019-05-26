_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

class Category extends Base
  getScyllaTables: ->
    [
      {
        name: 'categories_by_slug'
        keyspace: 'free_roam'
        fields:
          slug: 'text' # eg: starting-out
          id: 'timeuuid'
          name: 'text'
          description: 'text'
          type: {type: 'text', defaultFn: -> 'rv'}
          priority: 'int'
          data: 'json'
        primaryKey:
          partitionKey: ['type']
          clusteringColumns: ['slug']
      }
    ]

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from 'categories_by_slug'
    .limit limit
    .run()
    .then (categories) ->
      _.orderBy categories, 'priority'
    .map @defaultOutput

module.exports = new Category()
