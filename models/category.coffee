_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

tables = [
  {
    name: 'categories'
    keyspace: 'free_roam'
    fields:
      id: 'text' # eg: starting-out
      name: 'text'
      description: 'text'
      type: 'text'
      priority: 'int'
      data: 'text'
    primaryKey:
      partitionKey: ['type']
      clusteringColumns: ['id']
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
      cknex().update 'categories'
      .set _.omit category, ['type', 'id']
      .where 'type', '=', category.type
      .where 'id', '=', category.id
      .run()
    ]

  getAll: ({limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'categories'
    .limit limit
    .run()
    .then (categories) ->
      _.orderBy categories, 'priority'
    .map defaultCategoryOutput

module.exports = new Category()
