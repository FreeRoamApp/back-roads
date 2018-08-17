_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

tables = [
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

defaultCategory = (category) ->
  unless category?
    return null

  category = _.cloneDeep category

  category.data = JSON.stringify category.data

  _.defaults category, {
    type: 'rv'
  }

defaultCategoryOutput = (category) ->
  unless category?
    return null

  if category.data
    category.data = try
      JSON.parse category.data
    catch
      {}

  category

class Category
  SCYLLA_TABLES: tables

  batchUpsert: (categories) =>
    Promise.map categories, (category) =>
      @upsert category

  upsert: (category) ->
    category = defaultCategory category

    Promise.all [
      cknex().update 'categories_by_slug'
      .set _.omit category, ['type', 'slug']
      .where 'type', '=', category.type
      .where 'slug', '=', category.slug
      .run()
    ]

  getAll: ({limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'categories_by_slug'
    .limit limit
    .run()
    .then (categories) ->
      _.orderBy categories, 'priority'
    .map defaultCategoryOutput

module.exports = new Category()
