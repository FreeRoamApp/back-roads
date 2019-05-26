_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class Item extends Base
  getScyllaTables: ->
    [
      {
        name: 'items_by_slug'
        keyspace: 'free_roam'
        fields:
          slug: 'text' # eg: surge-protector
          id: 'timeuuid'
          categories: 'json'
          name: 'text'
          why: 'text'
          what: 'text'
          videos: 'json' # json (array of video objects)
        primaryKey:
          partitionKey: ['slug']
      }
      {
        name: 'items_by_category'
        keyspace: 'free_roam'
        fields:
          slug: 'text' # eg: surge-protector
          id: 'timeuuid'
          category: 'text'
          name: 'text'
          why: 'text'
          what: 'text'
          videos: 'json' # json (array of video objects)
        primaryKey:
          partitionKey: ['category']
          clusteringColumns: ['slug']
      }
    ]
  getElasticSearchIndices: ->
    [
      {
        name: 'items'
        mappings:
          slug: {type: 'text'}
          name: {type: 'text'}
          categories: {type: 'text'}
          why: {type: 'text'}
          what: {type: 'text'}
      }
    ]

  upsert: (item) =>
    item = @defaultInput item

    Promise.all _.flatten [
      cknex().update 'items_by_slug'
      .set _.omit item, ['slug']
      .where 'slug', '=', item.slug
      .run()

      _.map JSON.parse(item.categories), (category) ->
        cknex().update 'items_by_category'
        .set _.omit item, ['categories', 'slug']
        .where 'category', '=', category
        .andWhere 'slug', '=', item.slug
        .run()

      @index item
    ]

  search: ({query}) ->
    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      body:
        query: query
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

  getBySlug: (slug) =>
    cknex().select '*'
    .from 'items_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getFirstByCategory: (category) =>
    cknex().select '*'
    .from 'items_by_category'
    .where 'category', '=', category
    .run {isSingle: true}
    .then @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from 'items_by_slug'
    .limit limit
    .run()
    .map @defaultOutput

  getAllByCategory: (category, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from 'items_by_category'
    .where 'category', '=', category
    .limit limit
    .run()
    .map @defaultOutput

module.exports = new Item()
