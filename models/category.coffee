_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class Category extends Base
  getScyllaTables: ->
    [
      {
        name: 'categories_by_slug'
        keyspace: 'free_roam'
        fields:
          slug: 'text' # eg: starting-out
          id: 'timeuuid'
          name: 'text'
          description: 'text'
          # TODO: drop and recreate this table w/o type field
          type: {type: 'text', defaultFn: -> 'rv'}
          filters: 'json'
          priority: 'int'
          data: 'json'
        primaryKey:
          partitionKey: ['type']
          clusteringColumns: ['slug']
      }
    ]

  getElasticSearchIndices: ->
    [
      {
        name: 'categories'
        mappings:
          slug: {type: 'keyword'}
          name: {type: 'text'}
          description: {type: 'text'}
          filters: {type: 'object'}
          priority: {type: 'integer'}
          data: {type: 'object'}
      }
    ]

  getAll: ({rig, experience, hookupPreference, limit} = {}) =>
    limit ?= 30

    filters = {}
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
        # sort: 'priority'
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}
    .then (categories) ->
      _.orderBy categories, (category) ->
        if category.data?.sortFilters
          hasRig = category.data.sortFilters.rigType.indexOf(rig) isnt -1
          hasExperience = category.data.sortFilters.experience.indexOf(experience) isnt -1
          hasHookupPreference = category.data.sortFilters.hookupPreference.indexOf(hookupPreference) isnt -1
          isMatch = hasRig and hasExperience and hasHookupPreference
          priority = if isMatch then category.priority else 999
        else
          priority = category.priority
        priority
      , 'asc'


    # cknex().select '*'
    # .from 'categories_by_slug'
    # .limit limit
    # .run()
    # .then (categories) ->
    #   _.orderBy categories, 'priority'
    # .map @defaultOutput

module.exports = new Category()
