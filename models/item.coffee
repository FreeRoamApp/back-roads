_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class Item extends Base
  SCYLLA_TABLES: [
    {
      name: 'items_by_slug'
      keyspace: 'free_roam'
      fields:
        slug: 'text' # eg: surge-protector
        id: 'timeuuid'
        categories: 'text'
        name: 'text'
        why: 'text'
        what: 'text'
        videos: 'text' # json (array of video objects)
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
        videos: 'text' # json (array of video objects)
      primaryKey:
        partitionKey: ['category']
        clusteringColumns: ['slug']
    }
  ]
  ELASTICSEARCH_INDICES: [
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
      index: @ELASTICSEARCH_INDICES[0].name
      type: @ELASTICSEARCH_INDICES[0].name
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

  defaultInput: (item) ->
    unless item?
      return null

    item.categories = JSON.stringify item.categories
    item.videos = JSON.stringify item.videos

    _.defaults item, {
    }

  defaultOutput: (item) ->
    unless item?
      return null

    if item.videos
      item.videos = try
        JSON.parse item.videos
      catch
        {}

    item

module.exports = new Item()
