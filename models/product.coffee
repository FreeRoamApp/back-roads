_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

tables = [
  {
    name: 'products_by_slug'
    keyspace: 'free_roam'
    fields:
      slug: 'text' # eg: kebab-case name
      id: 'timeuuid'
      itemSlug: 'text'
      source: 'text' # eg amazon
      sourceId: 'text' # eg amazon
      name: 'text'
      description: 'text'
      sellers: 'text' # [{seller: 'amazon', sellerId: 'amazon-id'}]
      reviewersLiked: {type: 'set', subType: 'text'}
      reviewersDisliked: {type: 'set', subType: 'text'}
      data: 'text'
    primaryKey:
      partitionKey: ['slug']
  }
  {
    name: 'products_by_itemSlug'
    keyspace: 'free_roam'
    fields:
      slug: 'text' # eg: az-amazonid
      id: 'timeuuid'
      itemSlug: 'text'
      source: 'text' # eg amazon
      sourceId: 'text' # eg amazon
      name: 'text'
      description: 'text'
      reviewersLiked: {type: 'set', subType: 'text'}
      reviewersDisliked: {type: 'set', subType: 'text'}
      data: 'text'
    primaryKey:
      partitionKey: ['itemSlug']
      clusteringColumns: ['slug']
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
    Promise.map products, (product) =>
      @upsert product

  upsert: (product) ->
    product = defaultProduct product

    Promise.all [
      cknex().update 'products_by_slug'
      .set _.omit product, ['slug']
      .where 'slug', '=', product.slug
      .run()

      cknex().update 'products_by_itemSlug'
      .set _.omit product, ['itemSlug', 'slug']
      .where 'itemSlug', '=', product.itemSlug
      .andWhere 'slug', '=', product.slug
      .run()
    ]

  getBySlug: (slug) ->
    cknex().select '*'
    .from 'products_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then defaultProductOutput

  getAllByItemSlug: (itemSlug, {limit} = {}) ->
    limit ?= 10

    cknex().select '*'
    .from 'products_by_itemSlug'
    .where 'itemSlug', '=', itemSlug
    .limit limit
    .run()
    .map defaultProductOutput

  getFirstByItemSlug: (itemSlug) ->
    cknex().select '*'
    .from 'products_by_itemSlug'
    .where 'itemSlug', '=', itemSlug
    .limit 1
    .run {isSingle: true}
    .then defaultProductOutput


module.exports = new Product()
