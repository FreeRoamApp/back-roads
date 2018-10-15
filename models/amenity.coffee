_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

# low to high
ICON_ORDER = ['gas', 'propane', 'groceries', 'water', 'dump']

scyllaFields =
  # common between all places
  slug: 'text' # eg: old-settlers-rv-park
  id: 'timeuuid'
  name: 'text'
  location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
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

  amenities: 'text' # json
  prices: 'text' # json

class Amenity extends PlaceBase
  SCYLLA_TABLES: [
    {
      name: 'amenities_by_slug'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['slug']
    }
    {
      name: 'amenities_by_id'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'amenities'
      mappings:
        # common between all places
        slug: {type: 'text'}
        name: {type: 'text'}
        location: {type: 'geo_point'}
        rating: {type: 'integer'}
        thumbnailUrl: {type: 'text'}
        # end common
        amenities: {type: 'text'} # array
    }
  ]

  defaultInput: (amenity) ->
    unless amenity?
      return null

    # transform existing data
    amenity = _.defaults {
      address: JSON.stringify amenity.address
      amenities: JSON.stringify amenity.amenities
      prices: JSON.stringify amenity.prices
    }, amenity


    # add data if non-existent
    _.defaults amenity, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (amenity) ->
    unless amenity?
      return null

    jsonFields = [
      'address', 'amenities', 'prices'
    ]
    _.forEach jsonFields, (field) ->
      try
        amenity[field] = JSON.parse amenity[field]
      catch
        {}

    _.defaults {type: 'amenity'}, amenity

  defaultESOutput: (amenity) ->
    amenity = _.defaults {
      icon: _.orderBy(amenity.amenities, (amenity) ->
        ICON_ORDER.indexOf(amenity)
      , ['desc'])[0]
    }, _.pick amenity, ['id', 'slug', 'name', 'location', 'amenities']

module.exports = new Amenity()
