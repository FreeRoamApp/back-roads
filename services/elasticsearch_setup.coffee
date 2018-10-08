Promise = require 'bluebird'
_ = require 'lodash'

CacheService = require './cache'
elasticsearch = require './elasticsearch'
config = require '../config'

# TODO

class ElasticsearchSetupService
  setup: (indices) =>
    CacheService.lock 'elasticsearch_setup7', =>
      Promise.each indices, @createIndexIfNotExist
    , {expireSeconds: 300}

  createIndexIfNotExist: (index) ->
    console.log 'create index', index
    elasticsearch.indices.create {
      index: index.name
      body:
        mappings:
          "#{index.name}":
            properties:
              index.mappings
        settings:
          number_of_shards: 3
          number_of_replicas: 2
      }
      .catch (err) ->
        # add any new mappings
        Promise.all _.map index.mappings, (value, key) ->
          elasticsearch.indices.putMapping {
            index: index.name
            type: "#{index.name}"
            body:
              "#{index.name}":
                properties:
                  "#{key}": value
          }
        .catch -> null
    # Promise.resolve null

module.exports = new ElasticsearchSetupService()
