_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

# main should be like yelp, kayak, etc...? search page. when typing, prepopulate: boondocking, rv park, walmart
# TODO: overnights_translations_by_slug_and_language
# override english values

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
    # administrativeArea: 'text' # state / province / region. iso when avail
    # postalCode: 'text'
    # country: 'text' # 2 char iso
  contact: 'text' # json
    # phone
    # email
    # website
  # end common
  subType: 'text' # walmart, etc...
  noise: 'text' # json {day: {value: 3, count: 1}, night: {value: 0, count: 1}}
  safety: 'text' # json {value: 3, count: 1}
  cellSignal: 'text' # json {verizon_lte: {signal: 7}, att: {signal: 3}} 1-5
  maxDays: 'int'

class Overnight extends PlaceBase
  SCYLLA_TABLES: [
    {
      name: 'overnights_by_slug'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['slug']
    }
    {
      name: 'overnights_by_id'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'overnights'
      mappings:
        # commeon
        slug: {type: 'text'}
        name: {type: 'text'}
        location: {type: 'geo_point'}
        rating: {type: 'integer'}
        thumbnailPrefix: {type: 'text'}
        # end common
        subType: {type: 'text'}
        noise: {type: 'object'}
        safety: {type: 'integer'}
        cellSignal: {type: 'object'}
        maxDays: {type: 'integer'}
    }
  ]

  seasonalFields: []

  defaultInput: (overnight) ->
    unless overnight?
      return null

    # transform existing data
    overnight = _.defaults {
      safety: JSON.stringify overnight.safety
      noise: JSON.stringify overnight.noise
      cellSignal: JSON.stringify overnight.cellSignal
      address: JSON.stringify overnight.address
      contact: JSON.stringify overnight.contact
    }, overnight

    # add data if non-existent
    _.defaults overnight, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (overnight) ->
    unless overnight?
      return null

    jsonFields = [
      'safety', 'noise', 'cellSignal', 'address', 'contact'
    ]
    _.forEach jsonFields, (field) ->
      try
        overnight[field] = JSON.parse overnight[field]
      catch
        {}

    _.defaults {type: 'overnight'}, overnight

  defaultESInput: (overnight) ->
    _.defaults {
      id: "#{overnight.id}"
      safety: if overnight.safety
        overnight.safety?.value
      noise: if overnight.noise
        _.mapValues overnight.noise, ({value}, time) -> value
    }, overnight

  defaultESOutput: (overnight) ->
    amenity = _.defaults {
      type: 'overnight'
      icon: if overnight.subType in ['walmart', 'restArea', 'casino'] \
            then _.snakeCase overnight.subType
            else 'default'
    }, _.pick overnight, [
      'slug', 'name', 'location', 'rating', 'thumbnailPrefix'
    ]

module.exports = new Overnight()
