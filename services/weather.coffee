request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'
DarkSky = require 'dark-sky'
moment = require 'moment'

Campground = require '../models/campground'
Overnight = require '../models/overnight'
CacheService = require './cache'
KueCreateService = require './kue_create'
config = require '../config'

PLACE_TYPES =
  campground: Campground
  overnight: Overnight

ONE_MINUTE_SECONDS = 60
FORECAST_PLACE_TIMEOUT_MS = 20000
# ONE_HOUR_SECONDS = 3600

class WeatherService
  constructor: ->
    @darkSky = new DarkSky config.DARK_SKY_SECRET_KEY

  getForecast: ({location}) ->
    @darkSky.coordinates {
      lat: location.lat
      lng: location.lon
    }
    .exclude 'minutely,hourly'
    .get()

  forecastPlace: ({id, type}) =>
    PlaceModel = PLACE_TYPES[type]
    PlaceModel.getById id
    .then (place) =>
      @getForecast {location: place.location}
      .then (forecast) ->
        dailyForecast = forecast.daily.data
        daily = _.map dailyForecast, (day) ->
          day.precipTotal = Math.round(100 * day.precipIntensity * 24) / 100
          day.day = moment.unix(day.time).format 'YYYY-MM-DD'
          day = _.pick day, ['day', 'precipProbability', 'precipType', 'precipTotal', 'temperatureHigh', 'temperatureLow', 'windSpeed', 'windGust', 'windBearing', 'uvIndex', 'cloudCover', 'icon', 'summary', 'time']
        forecast = {daily}
        forecast = _.defaults {
          minHigh: _.minBy(dailyForecast, 'temperatureHigh').temperatureHigh
          maxHigh: _.maxBy(dailyForecast, 'temperatureHigh').temperatureHigh
          minLow: _.minBy(dailyForecast, 'temperatureLow').temperatureLow
          maxLow: _.maxBy(dailyForecast, 'temperatureLow').temperatureLow
          maxWindGust: _.maxBy(dailyForecast, 'windGust').windGust
          maxWindSpeed: _.maxBy(dailyForecast, 'windSpeed').windSpeed
          rainyDays: _.filter(
            dailyForecast, ({precipProbability}) -> precipProbability > 0.4
          ).length
        }, forecast
        PlaceModel.upsertByRow place, {forecast}

  forecastPlaces: =>
    console.log 'update places'
    # TODO: need to go through every "place" somehow. problem is they're
    # all in their own buckets. could do buckets by first letter of id?
    # should probably just use elasticsearch
    start = Date.now()
    newForecastMinPlaceSlug = null
    forecastIdCacheKey = CacheService.KEYS.FORECAST_ID
    CacheService.lock CacheService.LOCKS.FORECAST, ->
      CacheService.get forecastIdCacheKey
      .then (forecastMinPlaceSlug) ->
        # forecastMinPlaceSlug = placeType:id
        forecastMinPlaceSlug ?= 'campground:0'
        [type, minPlaceSlug] = forecastMinPlaceSlug.split ':'
        console.log 'get by minId', type, minPlaceSlug
        PLACE_TYPES[type].getAllByMinSlug minPlaceSlug
        .then (places) ->
          if _.isEmpty places
            types = _.keys PLACE_TYPES
            currentTypeIndex = types.indexOf(type)
            if currentTypeIndex + 1 is types.length
              console.log 'end'
              return # just end it here, don't restart until next day
            else
              console.log 'bump'
              newType = types[(currentTypeIndex + 1) % types.length]
              newForecastMinPlaceSlug = "#{newType}:0"
          else
            newForecastMinPlaceSlug = "#{type}:#{_.last(places).slug}"
          console.log 'new', newForecastMinPlaceSlug
          console.log 'places', places.length
          # add each place to kue
          # once all processed, call update again with new forecastMinPlaceSlug
          Promise.map places, ({id}) ->
            KueCreateService.createJob {
              job: {id, type}
              type: KueCreateService.JOB_TYPES.FORECAST_PLACE
              ttlMs: FORECAST_PLACE_TIMEOUT_MS
              priority: 'normal'
              waitForCompletion: true
            }
            .catch (err) ->
              console.log 'caught', id, err
    , {expireSeconds: 120, unlockWhenCompleted: true}
    .tap (responses) ->
      CacheService.set forecastIdCacheKey, newForecastMinPlaceSlug, {
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
        @forecastPlaces()
      null


module.exports = new WeatherService()
