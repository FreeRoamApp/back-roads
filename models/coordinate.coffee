_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

scyllaFields =
  # common between all places
  slug: 'text' # eg: old-settlers-rv-park
  id: 'timeuuid'
  userId: 'uuid'
  name: 'text'
  location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
  address: 'json' # json

class Coordinate extends PlaceBase
  getScyllaTables: ->
    [
      {
        name: 'coordinates_by_userId_and_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId', 'slug']
      }
      {
        name: 'coordinates_by_userId_and_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId', 'id']
      }
    ]
  getElasticSearchIndices: ->
    [
      {
        name: 'coordinates'
        mappings:
          # common
          slug: {type: 'text'}
          name: {type: 'text'}
          location: {type: 'geo_point'}
          address: {type: 'object'}
          # end common
          userId: {type: 'text'}
      }
    ]

  getByUserIdAndSlug: (userId, slug) =>
    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .andWhere 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getByUserIdAndId: (userId, id) =>
    cknex().select '*'
    .from @getScyllaTables()[1].name
    .where 'userId', '=', userId
    .andWhere 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  defaultOutput: (coordinate) ->
    coordinate = super coordinate
    _.defaults {type: 'coordinate'}, coordinate

  defaultESInput: (coordinate) ->
    _.defaults {
      id: "#{coordinate.id}"
    }, coordinate

  defaultESOutput: (coordinate) ->
    amenity = _.defaults {
      type: 'coordinate'
    }, _.pick coordinate, [
      'slug', 'name', 'location'
    ]

module.exports = new Coordinate()
