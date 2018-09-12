_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

SCYLLA_TABLE_NAME = 'amenities_by_slug'
ELASTICSEARCH_INDEX_NAME = 'amenities'

tables = [
  {
    name: SCYLLA_TABLE_NAME
    keyspace: 'free_roam'
    fields:
      # common between all places
      slug: 'text' # eg: old-settlers-rv-park
      id: 'timeuuid'
      name: 'text'
      location: {type: 'set', subType: 'double'} # coordinates
      rating: 'double'
      ratingCount: 'int'
      details: 'text' # wikipedia style info. can be stylized with markdown
      address: 'text' # json:
        # thoroughfare: 'text' # address
        # premise: 'text' # apt, suite, etc...
        # locality: 'text' # city / town
        # administrative_area: 'text' # state / province / region. iso when avail
        # postal_code: 'text'
        # country: 'text' # 2 char iso
      # end common

    primaryKey:
      partitionKey: ['slug']
  }
]

elasticSearchIndices = [
  {
    name: ELASTICSEARCH_INDEX_NAME
    mappings:
      # common between all places
      name: {type: 'text'}
      location: {type: 'geo_point'}
      rating: {type: 'integer'}
      # end common
  }
]

class Amenity extends PlaceBase
  SCYLLA_TABLE_NAME: SCYLLA_TABLE_NAME
  SCYLLA_TABLES: tables
  ELASTICSEARCH_INDEX_NAME: ELASTICSEARCH_INDEX_NAME
  ELASTICSEARCH_INDICES: elasticSearchIndices

  defaultInput: (amenity) ->
    unless amenity?
      return null

    # transform existing data
    amenity = _.defaults {
      address: JSON.stringify amenity.address
    }, amenity


    # add data if non-existent
    _.defaults amenity, {
      rating: 0
    }

  defaultOutput: (amenity) ->
    unless amenity?
      return null

    jsonFields = [
      'address'
    ]
    _.forEach jsonFields, (field) ->
      try
        amenity[field] = JSON.parse amenity[field]
      catch
        {}

    _.defaults {type: 'amenity'}, amenity


module.exports = new Amenity()
