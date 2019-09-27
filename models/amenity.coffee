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
  userId: {type: 'uuid', defaultFn: -> null} # creator id
  name: 'text'
  location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
  rating: 'double'
  ratingCount: 'int'
  details: 'text' # wikipedia style info. can be stylized with markdown
  thumbnailPrefix: 'text'
  address: 'json'
    # thoroughfare: 'text' # address
    # premise: 'text' # apt, suite, etc...
    # locality: 'text' # city / town
    # administrativeArea: 'text' # state / province / region. iso when avail
    # postal_code: 'text'
    # country: 'text' # 2 char iso
  contact: 'json'
    # phone
    # email
    # website
  subType: 'text' # walmart, etc...
  # end common

  amenities: 'json' # json
  prices: 'json' # json

class Amenity extends PlaceBase
  getScyllaTables: ->
    [
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

  getElasticSearchIndices: ->
    [
      {
        name: 'amenities'
        mappings:
          # common between all places
          slug: {type: 'keyword'}
          name: {type: 'text'}
          location: {type: 'geo_point'}
          rating: {type: 'double'}
          ratingCount: {type: 'integer'}
          thumbnailPrefix: {type: 'keyword'}
          subType: {type: 'keyword'}
          # end common
          amenities: {type: 'text'} # array
      }
    ]

  defaultOutput: (amenity) ->
    unless amenity?
      return null

    amenity = super amenity
    _.defaults {type: 'amenity'}, amenity

  defaultESOutput: (amenity) ->
    hasAttachments = Boolean amenity.thumbnailPrefix # TODO
    amenity = _.defaults {
      type: 'amenity'
      hasAttachments: hasAttachments
    }, _.pick amenity, [
      'id', 'slug', 'name', 'location', 'rating', 'amenities', 'hasAttachments'
    ]

module.exports = new Amenity()
