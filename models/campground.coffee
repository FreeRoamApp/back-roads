_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

# main should be like yelp, kayak, etc...? search page. when typing, prepopulate: boondocking, rv park, walmart
# TODO: campgrounds_translations_by_slug_and_language
# override english values

scyllaFields =
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
    # administrativeArea: 'text' # state / province / region. iso when avail
    # postalCode: 'text'
    # country: 'text' # 2 char iso
  # end common

  drivingInstructions: 'text'

  siteCount: 'text' # json: {"maxSize(var)": count}, eg {50: 5, 40: 20} means 5 spots for 40-50ft, 20 spots for 0-40 ft. use unknown for size if unknown
  distanceTo: 'text' # json {groceries: 25, walmart: 10} all in miles

  roadDifficulty: 'text' # json {value: 3, count: 1}
  crowds: 'text' # json {winter: {value: 2, count: 1} ... }
  fullness: 'text' # json {winter: {value: 2, count: 1} ... }
  noise: 'text' # json {day: {value: 3, count: 1}, night: {value: 0, count: 1}}
  shade: 'text' # json {value: 3, count: 1}
  safety: 'text' # json {value: 3, count: 1}
  cellSignal: 'text' # json {verizon_lte: {signal: 7}, att: {signal: 3}} 1-5

  maxDays: 'int'
  hasFreshWater: 'boolean'
  hasSewage: 'boolean'
  has30Amp: 'boolean'
  has50Amp: 'boolean'
  minPrice: 'int'
  maxPrice: 'int'
  maxLength: 'int'
  restrooms: 'text'
  videos: 'text' # json

class Campground extends PlaceBase
  SCYLLA_TABLES: [
    {
      name: 'campgrounds_by_slug'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['slug']
    }
    {
      name: 'campgrounds_by_id'
      keyspace: 'free_roam'
      fields: scyllaFields
      primaryKey:
        partitionKey: ['id']
    }
  ]
  ELASTICSEARCH_INDICES: [
    {
      name: 'campgrounds'
      mappings:
        slug: {type: 'text'}
        name: {type: 'text'}
        location: {type: 'geo_point'}
        rating: {type: 'integer'}
        roadDifficulty: {type: 'integer'}
        crowds: {type: 'object'}
        fullness: {type: 'object'}
        noise: {type: 'object'}
        shade: {type: 'integer'}
        safety: {type: 'integer'}
        cellSignal: {type: 'object'}
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

  defaultInput: (campground) ->
    unless campground?
      return null

    # transform existing data
    campground = _.defaults {
      siteCount: JSON.stringify campground.siteCount
      crowds: JSON.stringify campground.crowds
      fullness: JSON.stringify campground.fullness
      shade: JSON.stringify campground.shade
      safety: JSON.stringify campground.safety
      roadDifficulty: JSON.stringify campground.roadDifficulty
      noise: JSON.stringify campground.noise
      cellSignal: JSON.stringify campground.cellSignal
      restrooms: JSON.stringify campground.restrooms
      videos: JSON.stringify campground.videos
      address: JSON.stringify campground.address
    }, campground

    # add data if non-existent
    _.defaults campground, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (campground) ->
    unless campground?
      return null

    jsonFields = [
      'siteCount', 'crowds', 'fullness', 'shade', 'safety', 'roadDifficulty'
      'noise', 'cellSignal', 'restrooms', 'videos', 'address'
    ]
    _.forEach jsonFields, (field) ->
      try
        campground[field] = JSON.parse campground[field]
      catch
        {}

    _.defaults {type: 'campground'}, campground

  defaultESInput: (campground) ->
    _.defaults {
      id: "#{campground.id}"
      crowds: if campground.crowds
        _.mapValues campground.crowds, ({value}, season) -> value
      fullness: if campground.fullness
        _.mapValues campground.fullness, ({value}, season) -> value
      shade: if campground.shade
        campground.shade?.value
      safety: if campground.safety
        campground.safety?.value
      roadDifficulty: if campground.roadDifficulty
        campground.roadDifficulty?.value
      noise: if campground.noise
        _.mapValues campground.fullness, ({value}, time) -> value
      location: if campground.location
        {lat: campground.location[0], lon: campground.location[1]}
    }, campground

  defaultESOutput: (campground) ->
    _.pick campground, ['slug', 'name', 'location']

module.exports = new Campground()
