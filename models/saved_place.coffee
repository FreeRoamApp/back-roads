_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

scyllaFields =
  # common between all places
  id: 'timeuuid'
  userId: 'uuid'
  sourceType: 'text'
  sourceId: 'text'

class SavedPlace extends Base
  SCYLLA_TABLES: [
    {
      name: 'saved_places_by_userId'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: ['sourceId', 'sourceType']
    }
  ]
  # don't think we need elasticsearch for this since all values are grabbed
  # at runtime instead of location, name, etc... being stored in ES
  ELASTICSEARCH_INDICES: [
    # {
    #   name: 'saved_places'
    #   mappings:
    #     # common between all places
    #     location: {type: 'geo_point'}
    #     # end common
    #     userId: {type: 'text'}
    #     sourceType: {type: 'text'}
    #     sourceId: {type: 'text'}
    # }
  ]

  defaultInput: (savedPlace) ->
    unless savedPlace?
      return null

    # transform existing data
    savedPlace = _.defaults {
    }, savedPlace


    # add data if non-existent
    _.defaults savedPlace, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (savedPlace) ->
    unless savedPlace?
      return null

    jsonFields = []
    _.forEach jsonFields, (field) ->
      try
        savedPlace[field] = JSON.parse savedPlace[field]
      catch
        {}

    _.defaults {type: 'savedPlace'}, savedPlace

  # defaultESOutput: (savedPlace) ->
  #   savedPlace = _.defaults {
  #     icon: savedPlace.icon
  #     type: 'saved'
  #   }, _.pick savedPlace, ['id', 'name', 'location']


  search: ({query, sort, limit}, {outputFn} = {}) =>
    null

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput



module.exports = new SavedPlace()
