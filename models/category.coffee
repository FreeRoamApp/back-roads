_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

class Category extends Base
  SCYLLA_TABLES: [
    {
      name: 'categories_by_slug'
      keyspace: 'free_roam'
      fields:
        slug: 'text' # eg: starting-out
        id: 'timeuuid'
        name: 'text'
        description: 'text'
        type: 'text'
        priority: 'int'
        data: 'text'
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

  defaultInput: (category) ->
    unless category?
      return null

    category = _.cloneDeep category

    category.data = JSON.stringify category.data

    _.defaults category, {
      type: 'rv'
    }

  defaultOutput: (category) ->
    unless category?
      return null

    if category.data
      category.data = try
        JSON.parse category.data
      catch
        {}

    category

module.exports = new Category()
