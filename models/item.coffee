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
          decisions: 'json' # json (array of decision objects)
          videos: 'json' # json (array of video objects)
          filters: 'json'
          priority: 'int'
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
          decisions: 'json' # json (array of decision objects)
          videos: 'json' # json (array of video objects)
          filters: 'json'
          priority: 'int'
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
          filters: {type: 'object'}
          priority: {type: 'integer'}
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

  getNamesByCategory: (category) =>
    cknex().select 'name'
    .from 'items_by_category'
    .where 'category', '=', category
    .run()
    .map (item) -> item.name

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from 'items_by_slug'
    .limit limit
    .run()
    .map @defaultOutput

  getAllByCategory: (category, {rig, experience, hookupPreference, limit} = {}) =>
    limit ?= 30

    filters = {categories: category}
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

    # cknex().select '*'
    # .from 'items_by_category'
    # .where 'category', '=', category
    # .limit limit
    # .run()
    # .map @defaultOutput

module.exports = new Item()
