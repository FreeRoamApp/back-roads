Promise = require 'bluebird'
_ = require 'lodash'

CacheService = require './cache'
elasticsearch = require './elasticsearch'
config = require '../config'

# TODO

class ElasticsearchSetupService
  setup: (indices) =>
    CacheService.lock 'elasticsearch_setup6', =>
      Promise.each indices, @createIndexIfNotExist
    , {expireSeconds: 300}

  createIndexIfNotExist: (index) ->
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
    # Promise.resolve null

module.exports = new ElasticsearchSetupService()
