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
      tags: 'text' # TODO
      name: 'text'
      why: 'text'
      what: 'text'
    primaryKey:
      partitionKey: ['id']
  }
]

defaultItem = (item) ->
  unless item?
    return null

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

    Promise.all [
      cknex().update 'items_by_id'
      .set _.omit item, ['id']
      .where 'id', '=', item.id
      .run()
    ]

  getById: (id) ->
    cknex().select '*'
    .from 'items_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultItemOutput

  getAll: ({limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'items_by_id'
    .limit limit
    .run()
    .map defaultItemOutput

module.exports = new Item()
