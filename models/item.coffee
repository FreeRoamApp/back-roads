_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

tables = [
  {
    name: 'items_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'text' # eg: surge-protector
      categories: 'text'
      name: 'text'
      why: 'text'
      what: 'text'
    primaryKey:
      partitionKey: ['id']
  }
  {
    name: 'items_by_category'
    keyspace: 'free_roam'
    fields:
      id: 'text' # eg: surge-protector
      category: 'text'
      name: 'text'
      why: 'text'
      what: 'text'
    primaryKey:
      partitionKey: ['category']
      clusteringColumns: ['id']
  }
]

defaultItem = (item) ->
  unless item?
    return null

  item.categories = JSON.stringify item.categories

  _.defaults item, {
  }

defaultItemOutput = (item) ->
  unless item?
    return null

  item

class Item
  SCYLLA_TABLES: tables

  batchUpsert: (items) =>
    Promise.map items, (item) =>
      @upsert item

  upsert: (item) ->
    item = defaultItem item

    Promise.all _.flatten [
      cknex().update 'items_by_id'
      .set _.omit item, ['id']
      .where 'id', '=', item.id
      .run()

      _.map JSON.parse(item.categories), (category) ->
        cknex().update 'items_by_category'
        .set _.omit item, ['categories', 'id']
        .where 'category', '=', category
        .andWhere 'id', '=', item.id
        .run()
    ]

  getById: (id) ->
    cknex().select '*'
    .from 'items_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultItemOutput

  getFirstByCategory: (category) ->
    cknex().select '*'
    .from 'items_by_category'
    .where 'category', '=', category
    .run {isSingle: true}
    .then defaultItemOutput

  getAll: ({limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'items_by_id'
    .limit limit
    .run()
    .map defaultItemOutput

  getAllByCategory: (category, {limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'items_by_category'
    .where 'category', '=', category
    .limit limit
    .run()
    .map defaultItemOutput

module.exports = new Item()
