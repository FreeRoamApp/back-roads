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
  name: 'text'
  location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
  details: 'text' # wikipedia style info. can be stylized with markdown
  address: 'text' # json:
  contact: 'text' # json
  # end common

  drivingInstructions: 'text'

  siteCount: 'text' # json: {"maxSize(var)": count}, eg {50: 5, 40: 20} means 5 spots for 40-50ft, 20 spots for 0-40 ft. use unknown for size if unknown
  distanceTo: 'text' # json {groceries: {id: '', distance: 25, time: 22}} all in miles/min
  cellSignal: 'text' # json {verizon_lte: {signal: 3}, att: {signal: 3}} 1-5

  weather: 'text' # json {jan: {precip, tmin, tmax}, feb: {}, ...}

  pets: 'text' # json {dogs: bool, largeDogs: bool, multipleDogs: bool}
  padSurface: 'text'
  seasonOpenDayOfYear: 'int'
  seasonCloseDayOfYear: 'int'

  maxDays: 'int'
  hasFreshWater: 'boolean'
  hasSewage: 'boolean'
  has30Amp: 'boolean'
  has50Amp: 'boolean'
  minPrice: 'int'
  maxPrice: 'int'
  maxLength: 'int'
  restrooms: 'text'

class ReviewlessCampground extends PlaceBase
  SCYLLA_TABLES: [
    {
      name: 'reviewless_campgrounds_by_slug'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['slug']
    }
    {
      name: 'reviewless_campgrounds_by_id'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'reviewless_campgrounds'
      mappings:
        # commeon
        slug: {type: 'text'}
        name: {type: 'text'}
        location: {type: 'geo_point'}
        thumbnailPrefix: {type: 'text'}
        # end common
        distanceTo: {type: 'object'}
        weather: {type: 'object'}
        cellSignal: {type: 'object'}

        pets: {type: 'object'}
        padSurface: {type: 'text'}
        seasonOpenDayOfYear: {type: 'integer'}
        seasonCloseDayOfYear: {type: 'integer'}

        maxDays: {type: 'integer'}
        hasFreshWater: {type: 'boolean'}
        hasSewage: {type: 'boolean'}
        has30Amp: {type: 'boolean'}
        has50Amp: {type: 'boolean'}
        minPrice: {type: 'integer'}
        maxPrice: {type: 'integer'}
        maxLength: {type: 'integer'}
        restrooms: {type: 'object'}
    }
  ]

  seasonalFields: ['crowds', 'fullness']

  defaultInput: (reviewlessCampground) ->
    unless reviewlessCampground?
      return null

    # transform existing data
    reviewlessCampground = _.defaults {
      siteCount: JSON.stringify reviewlessCampground.siteCount
      pets: JSON.stringify reviewlessCampground.pets
      address: JSON.stringify reviewlessCampground.address
      contact: JSON.stringify reviewlessCampground.contact
      weather: JSON.stringify reviewlessCampground.weather
      distanceTo: JSON.stringify reviewlessCampground.distanceTo
      cellSignal: JSON.stringify reviewlessCampground.cellSignal
      restrooms: JSON.stringify reviewlessCampground.restrooms
    }, reviewlessCampground

    # add data if non-existent
    _.defaults reviewlessCampground, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (reviewlessCampground) ->
    unless reviewlessCampground?
      return null

    jsonFields = [
      'siteCount', 'pets', 'address', 'weather', 'cellSignal'
      'distanceTo', 'restrooms', 'contact'
    ]
    _.forEach jsonFields, (field) ->
      try
        reviewlessCampground[field] = JSON.parse reviewlessCampground[field]
      catch
        {}

    _.defaults {type: 'reviewlessCampground'}, reviewlessCampground

  defaultESInput: (reviewlessCampground) ->
    _.defaults {
      id: "#{reviewlessCampground.id}"
    }, reviewlessCampground

  defaultESOutput: (reviewlessCampground) ->
    reviewlessCampground = _.pick reviewlessCampground, [
      'slug', 'name', 'location', 'thumbnailPrefix'
    ]
    _.defaults {
      icon: 'reviewless'
      type: 'reviewlessCampground'
    }, reviewlessCampground

module.exports = new ReviewlessCampground()
