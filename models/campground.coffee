_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

# main should be like yelp, kayak, etc...? search page. when typing, prepopulate: boondocking, rv park, walmart
# TODO: campgrounds_translations_by_slug_and_language
# override english values

SCYLLA_TABLE_NAME = 'campgrounds_by_slug'
ELASTICSEARCH_INDEX_NAME = 'campgrounds'

tables = [
  {
    name: 'campgrounds_by_slug'
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

      drivingInstructions: 'text'

      siteCount: 'text' # json: {"maxSize(var)": count}, eg {50: 5, 40: 20} means 5 spots for 40-50ft, 20 spots for 0-40 ft. use unknown for size if unknown
      distanceTo: 'text' # json {groceries: 25, walmart: 10} all in miles

      # 0 my prius could get there, 5 need a truck, 10 need 4x4 high clearance van
      roadDifficulty: 'int'

      # 0 private spot, closest human 100yd+ away, 5 can see others, > 50 ft, 10 sardines
      crowds: 'text' # json {winter: 2, spring: 5, summer: 10, fall: 5}

      # 0 no one there / always spots available, 10 almost impossible to get a spot
      fullness: 'text' # json {winter: 2, spring: 5, summer: 10, fall: 5}

      # 0 silence, 5 occassional train / some road noise, 10 constant trains, highway noise
      noise: 'text' # json {day: 3, night: 0}

      # 0 no shade, 5 shade if you want it, 10 all shade
      shade: 'int'

      # 0 you might get murdered, 10 no worries at all
      safety: 'int'

      cellSignal: 'text' # json {verizon: {signal: 7, type: '4g'}, att: {signal: 3, type: '3g'}} 0-10 signal
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
    primaryKey:
      partitionKey: ['slug']
  }
]

elasticSearchIndices = [
  {
    name: 'campgrounds'
    mappings:
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

class Campground extends PlaceBase
  SCYLLA_TABLE_NAME: SCYLLA_TABLE_NAME
  SCYLLA_TABLES: tables
  ELASTICSEARCH_INDEX_NAME: ELASTICSEARCH_INDEX_NAME
  ELASTICSEARCH_INDICES: elasticSearchIndices

  defaultInput: (campground) ->
    unless campground?
      return null

    # transform existing data
    campground = _.defaults {
      siteCount: JSON.stringify campground.siteCount
      crowds: JSON.stringify campground.crowds
      fullness: JSON.stringify campground.fullness
      noise: JSON.stringify campground.noise
      cellSignal: JSON.stringify campground.cellSignal
      restrooms: JSON.stringify campground.restrooms
      videos: JSON.stringify campground.videos
      address: JSON.stringify campground.address
    }, campground


    # add data if non-existent
    _.defaults campground, {
      rating: 0
    }

  defaultOutput: (campground) ->
    unless campground?
      return null

    jsonFields = [
      'siteCount', 'crowds', 'fullness', 'noise', 'cellSignal',
      'restrooms', 'videos', 'address'
    ]
    _.forEach jsonFields, (field) ->
      try
        campground[field] = JSON.parse campground[field]
      catch
        {}

    _.defaults {type: 'campground'}, campground


module.exports = new Campground()
