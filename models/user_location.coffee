_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class UserLocation extends PlaceBase
  getScyllaTables: ->
    [
      {
        name: 'user_locations_by_userId'
        keyspace: 'free_roam'
        fields:
          userId: 'uuid'
          sourceType: 'text'
          sourceId: 'text'
          location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
          time: 'timestamp'
        primaryKey:
          partitionKey: ['userId']
      }
    ]

  getElasticSearchIndices: ->
    [
      {
        name: 'user_locations'
        mappings:
          userId: {type: 'text'}
          sourceType: {type: 'text'}
          sourceId: {type: 'text'}
          location: {type: 'geo_point'}
          time: {type: 'date'}
      }
    ]

  getByUserId: (userId) ->
    cknex().select '*'
    .from 'user_locations_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}

  defaultInput: (userLocation) ->
    unless userLocation?
      return null

    # transform existing data
    userLocation = _.defaults {
    }, userLocation


    # add data if non-existent
    _.defaults userLocation, {
      time: Date.now()
    }

  defaultOutput: (userLocation) ->
    unless userLocation?
      return null

    # jsonFields = []
    # _.forEach jsonFields, (field) ->
    #   try
    #     userLocation[field] = JSON.parse userLocation[field]
    #   catch
    #     {}

    _.defaults {type: 'userLocation'}, userLocation

  defaultESInput: (userLocation) ->
    _.defaults {
      id: "#{userLocation.userId}"
    }, userLocation

  defaultESOutput: (userLocation) ->
    userLocation = _.defaults {
      type: 'userLocation'
      icon: 'search'
    }, _.pick userLocation, [
      'userId', 'location', 'time', 'sourceType', 'sourceId'
    ]

module.exports = new UserLocation()
