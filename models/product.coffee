_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

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
  decisions: {type: 'set', subType: 'text'}
  videos: 'json' # (array of video objects)
  data: 'json'
  filters: 'json'
  priority: 'int'

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

  getElasticSearchIndices: ->
    [
      {
        name: 'products'
        mappings:
          slug: {type: 'keyword'}
          itemSlug: {type: 'keyword'}
          name: {type: 'text'}
          description: {type: 'text'}
          source: {type: 'keyword'}
          sourceId: {type: 'text'}
          sellers: {type: 'object'}
          decisions: {type: 'text'}
          videos: {type: 'object'}
          data: {type: 'object'}
          filters: {type: 'object'}
          priority: {type: 'integer'}
      }
    ]

  getBySlug: (slug) =>
    cknex().select '*'
    .from 'products_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getAllByItemSlug: (itemSlug, {rig, experience, hookupPreference, limit} = {}) =>
    limit ?= 10

    filters = {itemSlug}
    if rig
      filters['filters.rigType'] = rig
    if experience
      filters['filters.experience'] = experience
    if hookupPreference
      filters['filters.hookupPreference'] = hookupPreference

    filter = _.map filters, (value, key) ->
      {
        bool:
          must:
            match:
              "#{key}": value
      }

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      body:
        query:
          bool:
            filter: filter
        sort: 'priority'
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}


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
