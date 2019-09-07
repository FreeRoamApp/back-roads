_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
CacheService = require '../services/cache'

scyllaFields =
  # common between all places
  id: 'timeuuid'
  userId: 'uuid'
  name: 'text'
  notes: 'text'
  sourceType: 'text'
  sourceId: 'text'
  startTime: {type: 'timestamp', defaultFn: -> new Date()}
  endTime: {type: 'timestamp', defaultFn: -> new Date()}
  reviewId: 'uuid' # associated review
  attachments: 'json' # json
  tripIds: {type: 'list', subType: 'uuid'}
  status: {type: 'text', defaultFn: -> 'planned'} # planned | visited

class CheckIn extends Base
  getScyllaTables: ->
    [
      {
        name: 'check_ins_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['sourceId', 'sourceType']
      }
      {
        name: 'check_ins_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
    ]
  # don't think we need elasticsearch for this since all values are grabbed
  # at runtime instead of location, name, etc... being stored in ES
  getElasticSearchIndices: ->
    [
      # {
      #   name: 'check_ins'
      #   mappings:
      #     # common between all places
      #     location: {type: 'geo_point'}
      #     # end common
      #     userId: {type: 'text'}
      #     sourceType: {type: 'text'}
      #     sourceId: {type: 'text'}
      # }
    ]

  upsert: ({userId}) ->
    super
    .tap ->
      category = "#{CacheService.PREFIXES.CHECK_INS_GET_ALL}:#{userId}"
      CacheService.deleteByCategory category

  search: ({query, sort, limit}, {outputFn} = {}) ->
    null

  getById: (id) =>
    cknex().select '*'
    .from 'check_ins_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput

  getByUserIdAndSourceId: (userId, sourceId) =>
    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .andWhere 'sourceId', '=', sourceId
    .run {isSingle: true}
    .then @defaultOutput



module.exports = new CheckIn()
