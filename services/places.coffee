Promise = require 'bluebird'
_ = require 'lodash'

Amenity = require '../models/amenity'
Campground = require '../models/campground'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
CacheService = require './cache'
WeatherService = require './weather'
KueCreateService = require './kue_create'

ONE_MINUTE_SECONDS = 60
DAILY_UPDATE_PLACE_TIMEOUT = 20000
ONE_WEEK_S = 3600 * 24 * 7

PLACE_TYPES =
  campground: Campground
  overnight: Overnight
  amenity: Amenity

DAILY_UPDATE_TYPES = ['campground', 'overnight']

class PlacesService
  getByTypeAndId: (type, id, {userId} = {}) ->
    unless id
      return Promise.resolve null
    if type is 'coordinate'
      Coordinate.getByUserIdAndId userId, id
    else
      Model = PLACE_TYPES[type] or Campground
      Model.getById id

  upsertByTypeAndRow: (type, row, diff) ->
    PLACE_TYPES[type].upsertByRow row, diff

  getByTypeAndSlug: (type, slug) ->
    unless slug
      return Promise.resolve null
    (if type is 'amenity'
      Amenity.getBySlug slug
    else if type is 'overnight'
      Overnight.getBySlug slug
    else
      Campground.getBySlug slug
    )

  getBestBounding: ({bbox, location, type, count}) ->
    count ?= 10
    type ?= 'campground'
    # TODO: other types
    prefix = CacheService.PREFIXES.PLACE_BEST_BOUNDING
    key = "#{prefix}:#{location.lat}:#{location.lon}:#{type}:#{count}"
    CacheService.preferCache key, ->
      Campground.searchNearby location, {distance: 3}
      .then ({places}) ->
        places = _.take places, 20
        places = places.concat [{location}]
        minX = _.minBy places, ({location}) -> location.lon
        minY = _.minBy places, ({location}) -> location.lat
        maxX = _.maxBy places, ({location}) -> location.lon
        maxY = _.maxBy places, ({location}) -> location.lat
        {
          x1: if bbox?[0] then Math.min(bbox[0], minX.location.lon) else minX.location.lon
          y1: if bbox?[3] then Math.max(bbox[3], maxY.location.lat) else maxY.location.lat
          x2: if bbox?[2] then Math.max(bbox[2], maxX.location.lon) else maxX.location.lon
          y2: if bbox?[1] then Math.min(bbox[1], minY.location.lat) else minY.location.lat
        }
    , {expireSeconds: ONE_WEEK_S}

  updateDailyInfo: ({id, type}) =>
    @getByTypeAndId type, id
    .then (place) =>
      console.log 'place', place.slug
      Promise.all [
        WeatherService.getForecastDiff place
      ]
      .then ([forecastDiff]) =>
        @upsertByTypeAndRow place.type, place, forecastDiff


  updateAllDailyInfo: ->
    console.log 'update places'
    # TODO: need to go through every "place" somehow. problem is they're
    # all in their own buckets. could do buckets by first letter of id?
    # should probably just use elasticsearch
    start = Date.now()
    newDailyUpdateMinPlaceSlug = null
    dailyUpdateIdCacheKey = CacheService.KEYS.DAILY_UPDATE_ID
    CacheService.lock CacheService.LOCKS.DAILY_UPDATE, ->
      CacheService.get dailyUpdateIdCacheKey
      .then (dailyUpdateMinPlaceSlug) ->
        # dailyUpdateMinPlaceSlug = placeType:id
        dailyUpdateMinPlaceSlug ?= 'campground:0'
        [type, minPlaceSlug] = dailyUpdateMinPlaceSlug.split ':'
        console.log 'get by minId', type, minPlaceSlug
        PLACE_TYPES[type].getAllByMinSlug minPlaceSlug
        .then (places) ->
          if _.isEmpty places
            types = DAILY_UPDATE_TYPES
            currentTypeIndex = types.indexOf(type)
            if currentTypeIndex + 1 is types.length
              console.log 'end'
              return # just end it here, don't restart until next day
            else
              console.log 'bump'
              newType = types[(currentTypeIndex + 1) % types.length]
              newDailyUpdateMinPlaceSlug = "#{newType}:0"
          else
            newDailyUpdateMinPlaceSlug = "#{type}:#{_.last(places).slug}"
          console.log 'new', newDailyUpdateMinPlaceSlug
          console.log 'places', places.length
          # add each place to kue
          # once all processed, call update again with new dailyUpdateMinPlaceSlug
          Promise.map places, ({id}) ->
            KueCreateService.createJob {
              job: {id, type}
              type: KueCreateService.JOB_TYPES.DAILY_UPDATE_PLACE
              ttlMs: DAILY_UPDATE_PLACE_TIMEOUT
              priority: 'normal'
              waitForCompletion: true
            }
            .catch (err) ->
              console.log 'caught', id, err
    , {expireSeconds: 120, unlockWhenCompleted: true}
    .tap (responses) ->
      CacheService.set dailyUpdateIdCacheKey, newDailyUpdateMinPlaceSlug, {
        expireSeconds: ONE_MINUTE_SECONDS
      }
    .then (responses) =>
      isLocked = not responses
      if isLocked
        console.log 'skip (locked)'
      else
        # always be truthy for cron-check
        # successes = _.filter(responses).length or 1
        # key = CacheService.KEYS.FORECAST_SUCCESS_COUNT
        # CacheService.set key, successes, {expireSeconds: ONE_HOUR_SECONDS}
        @updateAllDailyInfo()
      null

module.exports = new PlacesService()
