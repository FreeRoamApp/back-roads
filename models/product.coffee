_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

tables = [
  {
    name: 'products_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'text' # eg: kebab-case name
      itemId: 'text'
      source: 'text' # eg amazon
      sourceId: 'text' # eg amazon
      name: 'text'
      description: 'text'
      sellers: 'text' # [{seller: 'amazon', sellerId: 'amazon-id'}]
      data: 'text'
    primaryKey:
      partitionKey: ['id']
  }
  {
    name: 'products_by_itemId'
    keyspace: 'free_roam'
    fields:
      id: 'text' # eg: az-amazonid
      itemId: 'text'
      source: 'text' # eg amazon
      sourceId: 'text' # eg amazon
      name: 'text'
      description: 'text'
      data: 'text'
    primaryKey:
      partitionKey: ['itemId']
      clusteringColumns: ['id']
  }
]

defaultProduct = (product) ->
  unless product?
    return null

  product = _.cloneDeep product

  product.data = JSON.stringify product.data

  _.defaults product, {
  }

defaultProductOutput = (product) ->
  unless product?
    return null

  if product.data
    product.data = try
      JSON.parse product.data
    catch
      {}

  product

class Product
  SCYLLA_TABLES: tables

  batchUpsert: (products) =>
    console.log 'batch prod'
    Promise.map products, (product) =>
      @upsert product

  upsert: (product) ->
    product = defaultProduct product

    console.log 'upsitem', product

    Promise.all [
      cknex().update 'products_by_id'
      .set _.omit product, ['id']
      .where 'id', '=', product.id
      .run()

      cknex().update 'products_by_itemId'
      .set _.omit product, ['itemId', 'id']
      .where 'itemId', '=', product.itemId
      .andWhere 'id', '=', product.id
      .run()
    ]

  getById: (id) ->
    cknex().select '*'
    .from 'products_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultProductOutput

  getAllByItemId: (itemId, {limit} = {}) ->
    limit ?= 10

    cknex().select '*'
    .from 'products_by_itemId'
    .where 'itemId', '=', itemId
    .limit limit
    .run()
    .map defaultProductOutput

  getFirstByItemId: (itemId) ->
    cknex().select '*'
    .from 'products_by_itemId'
    .where 'itemId', '=', itemId
    .limit 1
    .run {isSingle: true}
    .then defaultProductOutput


module.exports = new Product()
