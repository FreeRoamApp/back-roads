_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

scyllaFields =
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
  data: 'json'

class Product extends Base
  getScyllaTables: ->
    [
      {
        name: 'products_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['slug']
      }
      {
        name: 'products_by_itemSlug'
        keyspace: 'free_roam'
        fields: scyllaFields
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

  getSlugsByItemSlug: (itemSlug) =>
    cknex().select 'slug'
    .from 'products_by_itemSlug'
    .where 'itemSlug', '=', itemSlug
    .run()
    .map (product) -> product.slug

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .limit limit
    .run()
    .map @defaultOutput


module.exports = new Product()
