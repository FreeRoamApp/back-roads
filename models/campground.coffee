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
  location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
  rating: 'double'
  ratingCount: 'int'
  details: 'text' # wikipedia style info. can be stylized with markdown
  thumbnailPrefix: 'text'
  address: 'json' # json:
    # thoroughfare: 'text' # address
    # premise: 'text' # apt, suite, etc...
    # locality: 'text' # city / town
    # administrativeArea: 'text' # state / province / region. iso when avail
    # postalCode: 'text'
    # country: 'text' # 2 char iso
  contact: 'json' # json {website, phone, email}
  # end common

  drivingInstructions: 'text'

  siteCount: 'json' # json: {"maxSize(var)": count}, eg {50: 5, 40: 20} means 5 spots for 40-50ft, 20 spots for 0-40 ft. use unknown for size if unknown
  distanceTo: 'json' # json {groceries: {id: '', distance: 25, time: 22}} all in miles/min

  roadDifficulty: 'json' # json {value: 3, count: 1}
  crowds: 'json' # json {winter: {value: 2, count: 1} ... }
  fullness: 'json' # json {winter: {value: 2, count: 1} ... }
  noise: 'json' # json {day: {value: 3, count: 1}, night: {value: 0, count: 1}}
  shade: 'json' # json {value: 3, count: 1}
  safety: 'json' # json {value: 3, count: 1}
  cellSignal: 'json' # json {verizon_lte: {signal: 3}, att: {signal: 3}} 1-5
  cleanliness: 'json' # json {value: 3, count: 1}

  weather: 'json' # json {jan: {precip, tmin, tmax}, feb: {}, ...}
  forecast: 'json' # json [d1, d2, d3, d4, ...] d1 = {precipProbability, precipType, temperatureHigh, temperatureLow, windSpeed, windGust, windBearing, uvIndex, cloudCover, icon, summary, time}

  pets: 'json' # json {allowed: bool, dogs: bool, largeDogs: bool, multipleDogs: bool}
  padSurface: 'text' # gravel, paved, dirt
  entryType: 'text' # back-in, pull-thru
  allowedTypes: 'json' # json {motorhome: true, trailer: true, tent: true}
  seasonOpenDayOfYear: 'int'
  seasonCloseDayOfYear: 'int'
  attachmentCount: 'int'

  source: 'text' # empty (user), coe, rec.gov, usfs
  subType: {type: 'text', defaultFn: -> 'public'} # private, public
  # or... isPrivate: boolean for rvParks?
  # affiliations: goodSam, passportAmerica, etc...

  maxDays: 'int'
  hasFreshWater: 'boolean'
  hasSewage: 'boolean'
  has30Amp: 'boolean'
  has50Amp: 'boolean'
  # minPrice: 'int'
  # maxPrice: 'int'
  # TODO: separate table for campground_prices_paid_by_id?
  # TODO: or use review_extras (though can't pull in govt data for that)
  prices: 'json' # json: {all: {min, max, avg, mode}, motorhome: {}}
  maxLength: 'int'
  restrooms: 'json'
  videos: 'json' # json

  agencySlug: 'text'
  regionSlug: 'text'
  officeSlug: 'text'


class Campground extends PlaceBase
  getScyllaTables: ->
    [
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

  getElasticSearchIndices: ->
    [
      {
        name: 'campgrounds'
        mappings:
          # common
          slug: {type: 'keyword'}
          name: {type: 'text'}
          location: {type: 'geo_point'}
          rating: {type: 'double'}
          ratingCount: {type: 'integer'}
          thumbnailPrefix: {type: 'keyword'}
          address: {type: 'object'}
          # end common
          distanceTo: {type: 'object'}
          roadDifficulty: {type: 'integer'}
          crowds: {type: 'object'}
          fullness: {type: 'object'}
          noise: {type: 'object'}
          shade: {type: 'integer'}
          safety: {type: 'integer'}
          cellSignal: {type: 'object'}
          cleanliness: {type: 'integer'}
          weather: {type: 'object'}
          forecast: {type: 'object'}

          pets: {type: 'object'}
          padSurface: {type: 'keyword'}
          entryType: {type: 'keyword'}
          allowedTypes: {type: 'object'}
          seasonOpenDayOfYear: {type: 'integer'}
          seasonCloseDayOfYear: {type: 'integer'}
          attachmentCount: {type: 'integer'}

          source: {type: 'keyword'} # empty (user), coe, rec.gov, usfs
          subType: {type: 'keyword'}

          maxDays: {type: 'integer'}
          hasFreshWater: {type: 'boolean'}
          hasSewage: {type: 'boolean'}
          has30Amp: {type: 'boolean'}
          has50Amp: {type: 'boolean'}

          # minPrice: {type: 'integer'}
          # maxPrice: {type: 'integer'}
          prices: {type: 'object'}

          maxLength: {type: 'integer'}
          restrooms: {type: 'object'}

          agencySlug: {type: 'keyword'}
          regionSlug: {type: 'keyword'}
      }
    ]

  seasonalFields: ['crowds', 'fullness']

  defaultOutput: (campground) ->
    unless campground?
      return null
    campground = super campground

    campground = _.defaults {type: 'campground'}, campground
    campground = _.defaults campground, {ratingCount: 0, attachmentCount: 0}

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
      cleanliness: if campground.cleanliness
        campground.cleanliness?.value
      roadDifficulty: if campground.roadDifficulty
        campground.roadDifficulty?.value
      noise: if campground.noise
        _.mapValues campground.noise, ({value}, time) -> value
      forecast: _.omit campground.forecast, ['daily']
    }, campground

  defaultESOutput: (campground) ->
    campground = _.pick campground, [
      'id', 'slug', 'name', 'location', 'rating', 'ratingCount', 'prices'
    ]
    _.defaults {
      type: 'campground'
    }, campground

module.exports = new Campground()
