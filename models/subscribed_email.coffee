_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
config = require '../config'

class SubscribedEmail extends Base
  getScyllaTables: -> []
  getElasticSearchIndices: ->
    [
      {
        name: 'subscribed_emails'
        mappings:
          # id is userId
          email: {type: 'text'}
      }
    ]

  getAll: ({limit} = {}) =>
    limit ?= 10000

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      size: limit
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

module.exports = new SubscribedEmail()
