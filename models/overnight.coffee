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
  userId: {type: 'uuid', defaultFn: -> null} # creator id
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
  contact: 'json' # json
    # phone
    # email
    # website
  # end common
  subType: 'text' # walmart, etc...
  noise: 'json' # json {day: {value: 3, count: 1}, night: {value: 0, count: 1}}
  safety: 'json' # json {value: 3, count: 1}
  cellSignal: 'json' # json {verizon_lte: {signal: 7}, att: {signal: 3}} 1-5
  maxDays: 'int'

  forecast: 'json' # json [d1, d2, d3, d4, ...] d1 = {precipProbability, precipType, temperatureHigh, temperatureLow, windSpeed, windGust, windBearing, uvIndex, cloudCover, icon, summary, time}

  isAllowedCount: 'int'
  isNotAllowedCount: 'int'
  isAllowedScore: 'double'


class Overnight extends PlaceBase
  getScyllaTables: ->
    [
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
      {
        name: 'overnights_isAllowed_by_userId'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          id: 'timeuuid'
          overnightId: 'uuid'
          userId: 'uuid'
          isAllowed: 'boolean'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['overnightId']
      }
    ]
  getElasticSearchIndices: ->
    [
      {
        name: 'overnights'
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
          subType: {type: 'keyword'}
          noise: {type: 'object'}
          safety: {type: 'integer'}
          cellSignal: {type: 'object'}
          maxDays: {type: 'integer'}

          forecast: {type: 'object'} # {minHigh, maxHigh, minLow, maxLow, rainyDays}

          isAllowedCount: {type: 'integer'}
          isNotAllowedCount: {type: 'integer'}
          isAllowedScore: {type: 'double'}
      }
    ]

  seasonalFields: []

  getIsOvernightAllowedByUserIdAndOvernightId: (userId, overnightId) ->
    cknex().select '*'
    .from 'overnights_isAllowed_by_userId'
    .where 'userId', '=', userId
    .andWhere 'overnightId', '=', overnightId
    .run {isSingle: true}

  upsertIsAllowed: (overnightIsAllowed) ->
    overnightIsAllowed = @defaultIsAllowedInput overnightIsAllowed
    cknex().update 'overnights_isAllowed_by_userId'
    .set _.omit overnightIsAllowed, ['userId', 'overnightId']
    .where 'userId', '=', overnightIsAllowed.userId
    .andWhere 'overnightId', '=', overnightIsAllowed.overnightId
    .run()

  defaultIsAllowedInput: (overnightIsAllowed) ->
    # add data if non-existent
    _.defaults overnightIsAllowed, {
      id: cknex.getTimeUuid()
    }

  defaultOutput: (overnight) ->
    unless overnight?
      return null

    overnight = super overnight
    overnight = _.defaults {type: 'overnight'}, overnight
    overnight = _.defaults overnight, {ratingCount: 0, attachmentCount: 0}

  defaultESInput: (overnight) ->
    _.defaults {
      id: "#{overnight.id}"
      safety: if overnight.safety
        overnight.safety?.value or null
      noise: if overnight.noise
        _.mapValues overnight.noise, ({value}, time) -> value
      forecast: _.omit overnight.forecast, ['daily']
    }, overnight

  defaultESOutput: (overnight) ->
    hasAttachments = Boolean overnight.thumbnailPrefix # TODO
    amenity = _.defaults {
      type: 'overnight'
      hasAttachments: hasAttachments
    }, _.pick overnight, [
      'id', 'slug', 'name', 'location', 'rating', 'ratingCount',
      'subType', 'hasAttachments', 'isAllowedScore'
    ]

module.exports = new Overnight()
