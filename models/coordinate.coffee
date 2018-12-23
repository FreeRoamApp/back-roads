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
  address: 'text' # json

class Coordinate extends PlaceBase
  SCYLLA_TABLES: [
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
  ELASTICSEARCH_INDICES: [
    {
      name: 'coordinates'
      mappings:
        # commeon
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
    .from @SCYLLA_TABLES[0].name
    .where 'userId', '=', userId
    .andWhere 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

  getByUserIdAndId: (userId, id) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[1].name
    .where 'userId', '=', userId
    .andWhere 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  defaultInput: (coordinate) ->
    unless coordinate?
      return null

    # transform existing data
    coordinate = _.defaults {
      address: JSON.stringify coordinate.address
    }, coordinate

    # add data if non-existent
    _.defaults coordinate, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (coordinate) ->
    unless coordinate?
      return null

    jsonFields = ['address']
    _.forEach jsonFields, (field) ->
      try
        coordinate[field] = JSON.parse coordinate[field]
      catch
        {}

    _.defaults {type: 'coordinate'}, coordinate

  defaultESInput: (coordinate) ->
    _.defaults {
      id: "#{coordinate.id}"
    }, coordinate

  defaultESOutput: (coordinate) ->
    amenity = _.defaults {
      type: 'coordinate'
      icon: 'default'
    }, _.pick coordinate, [
      'slug', 'name', 'location'
    ]

module.exports = new Coordinate()
