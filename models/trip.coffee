_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

scyllaFields =
  # common between all places
  id: 'timeuuid'
  type: 'text' # past, future, custom
  userId: 'uuid'
  name: 'text'
  # 'set's don't appear to work with ordering
  checkInIds: {type: 'list', subType: 'uuid'}
  imagePrefix: 'text'

class Trip extends Base
  SCYLLA_TABLES: [
    {
      name: 'trips_by_userId'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: ['type', 'id']
    }
    {
      name: 'trips_by_id'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['id']
    }
  ]

  defaultInput: (trip) ->
    unless trip?
      return null

    # transform existing data
    trip = _.defaults {
    }, trip


    # add data if non-existent
    _.defaults trip, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (trip) ->
    unless trip?
      return null

    jsonFields = []
    _.forEach jsonFields, (field) ->
      try
        trip[field] = JSON.parse trip[field]
      catch
        {}

    trip

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput

  getById: (id) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[1].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getByUserIdAndType: (userId, type) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'userId', '=', userId
    .andWhere 'type', '=', type
    .limit 1
    .run {isSingle: true}
    .then @defaultOutput

  deleteCheckInIdById: (id, checkInId) =>
    @getById id
    .then (trip) =>
      @upsertByRow trip, {}, {remove: {checkInIds: [checkInId]}}


module.exports = new Trip()