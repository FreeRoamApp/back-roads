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
          privacy: 'text'
          location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
          time: {type: 'timestamp', defaultFn: -> new Date()}
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
          privacy: {type: 'text'}
          location: {type: 'geo_point'}
          time: {type: 'date'}
      }
    ]

  getByUserId: (userId) ->
    cknex().select '*'
    .from 'user_locations_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}

  defaultOutput: (userLocation) ->
    userLocation = super userLocation
    _.defaults {type: 'userLocation'}, userLocation

  defaultESInput: (userLocation) ->
    _.defaults {
      id: "#{userLocation.userId}"
      time: new Date()
    }, userLocation

  defaultESOutput: (userLocation) ->
    userLocation = _.defaults {
      type: 'userLocation'
      icon: 'search'
    }, _.pick userLocation, [
      'userId', 'location', 'time', 'sourceType', 'sourceId'
    ]

module.exports = new UserLocation()
