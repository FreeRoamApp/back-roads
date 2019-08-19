Promise = require 'bluebird'
_ = require 'lodash'
DarkSky = require 'dark-sky'
moment = require 'moment'

FeatureLookupService = require './feature_lookup'
config = require '../config'

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

  getForecastDiff: (place) =>
    Promise.all [
      @getForecast {location: place.location}
      FeatureLookupService.getFeaturesByLocation _.defaults {
        file: 'fire_weather'
      }, place.location
    ]
    .then ([forecast, fireWeather]) ->
      dailyForecast = forecast.daily.data
      daily = _.map dailyForecast, (day) ->
        day.precipTotal = Math.round(100 * day.precipIntensity * 24) / 100
        day.day = moment.unix(day.time).format 'YYYY-MM-DD'
        day = _.pick day, ['day', 'precipProbability', 'precipType', 'precipTotal', 'temperatureHigh', 'temperatureLow', 'windSpeed', 'windGust', 'windBearing', 'uvIndex', 'cloudCover', 'icon', 'summary', 'time']
      forecast = {daily}
      forecast = _.defaults {
        fireWeather: fireWeather?[0] or null
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
      {forecast}


module.exports = new WeatherService()
