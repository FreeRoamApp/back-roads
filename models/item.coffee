_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

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
      videos: 'text' # json (array of video objects)
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
      videos: 'text' # json (array of video objects)
    primaryKey:
      partitionKey: ['category']
      clusteringColumns: ['id']
  }
]

defaultItem = (item) ->
  unless item?
    return null

  item.categories = JSON.stringify item.categories
  item.videos = JSON.stringify item.videos

  _.defaults item, {
  }

defaultItemOutput = (item) ->
  unless item?
    return null

  if item.videos
    item.videos = try
      JSON.parse item.videos
    catch
      {}

  item

elasticSearchIndices = [
  {
    name: 'items'
    mappings:
      name: {type: 'text'}
      categories: {type: 'text'}
      why: {type: 'text'}
      what: {type: 'text'}
  }
]

class Item
  SCYLLA_TABLES: tables
  ELASTICSEARCH_INDICES: elasticSearchIndices

  batchUpsert: (items) =>
    Promise.map items, (item) =>
      Promise.all [
        @upsert item
        @index item
      ]

  index: (item) ->
    elasticsearch.index {
      index: 'items'
      type: 'items'
      id: item.id
      body: item
    }

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

  search: ({query}) ->
    console.log query
    elasticsearch.search {
      index: 'items'
      type: 'items'
      body:
        query: query
    }
    .then ({hits}) ->
      _.map hits.hits, '_source'

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
