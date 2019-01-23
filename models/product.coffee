_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

class Product extends Base
  getScyllaTables: ->
    [
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

  getBySlug: (slug) =>
    cknex().select '*'
    .from 'products_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getAllByItemSlug: (itemSlug, {limit} = {}) =>
    limit ?= 10

    cknex().select '*'
    .from 'products_by_itemSlug'
    .where 'itemSlug', '=', itemSlug
    .limit limit
    .run()
    .map @defaultOutput

  getFirstByItemSlug: (itemSlug) =>
    cknex().select '*'
    .from 'products_by_itemSlug'
    .where 'itemSlug', '=', itemSlug
    .limit 1
    .run {isSingle: true}
    .then @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .limit limit
    .run()
    .map @defaultOutput

  defaultInput: (product) ->
    unless product?
      return null

    product = _.cloneDeep product

    product.data = JSON.stringify product.data

    _.defaults product, {
    }

  defaultOutput: (product) ->
    unless product?
      return null

    if product.data
      product.data = try
        JSON.parse product.data
      catch
        {}

    product


module.exports = new Product()
