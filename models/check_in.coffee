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
  sourceType: 'text'
  sourceId: 'text'
  startTime: 'timestamp'
  endTime: 'timestamp'
  attachments: 'text' # json
  tripIds: {type: 'list', subType: 'uuid'}
  status: 'text' # planned | visited

class CheckIn extends Base
  SCYLLA_TABLES: [
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
  ELASTICSEARCH_INDICES: [
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

  defaultInput: (checkIn) ->
    unless checkIn?
      return null

    # transform existing data
    checkIn = _.defaults {
    }, checkIn


    # add data if non-existent
    _.defaults checkIn, {
      id: cknex.getTimeUuid()
      status: 'planned'
    }

  defaultOutput: (checkIn) ->
    unless checkIn?
      return null

    jsonFields = []
    _.forEach jsonFields, (field) ->
      try
        checkIn[field] = JSON.parse checkIn[field]
      catch
        {}

    checkIn

  # defaultESOutput: (checkIn) ->
  #   checkIn = _.defaults {
  #     icon: checkIn.icon
  #     type: 'saved'
  #   }, _.pick checkIn, ['id', 'name', 'location']


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
    .from @SCYLLA_TABLES[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput



module.exports = new CheckIn()
