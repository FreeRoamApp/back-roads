_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
request = require 'request-promise'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
config = require '../config'

scyllaFields =
  # common between all places
  id: 'timeuuid'
  type: 'text' # past, future, custom
  userId: 'uuid'
  name: 'text'
  privacy: 'text' # public, private, friends
  # 'set's don't appear to work with ordering
  checkInIds: {type: 'list', subType: 'uuid'}
  lastUpdateTime: 'timestamp'
  imagePrefix: 'text'

class Trip extends Base
  getScyllaTables: ->
    [
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
      lastUpdateTime: new Date()
      privacy: 'public'
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

  updateMapByRow: (trip) =>
    imagePrefix = "trips/#{trip.id}_profile"
    Promise.resolve request "#{config.SCREENSHOTTER_HOST}/screenshot",
      json: true
      qs:
        imagePrefix: imagePrefix
        clipY: 32
        viewportHeight: 424
        width: 600
        height: 360
        # TODO: https
        url: "http://#{config.FREE_ROAM_HOST}/travel-map-screenshot/#{trip.id}"
    .then =>
      @upsertByRow trip, {
        imagePrefix
      }

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput

  getById: (id) =>
    cknex().select '*'
    .from @getScyllaTables()[1].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getByUserIdAndType: (userId, type, {createIfNotExists} = {}) =>
    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .andWhere 'type', '=', type
    .limit 1
    .run {isSingle: true}
    .then (trip) =>
      if createIfNotExists and not trip and type in ['past', 'future']
        @upsert {
          type
          userId
          name: _.startCase type
        }
      else
        trip
    .then @defaultOutput


  deleteCheckInIdById: (id, checkInId) =>
    @getById id
    .then (trip) =>
      @upsertByRow trip, {}, {remove: {checkInIds: [checkInId]}}


module.exports = new Trip()
