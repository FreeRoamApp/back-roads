Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EmbedService = require '../services/embed'
GeocoderService = require '../services/geocoder'
ImageService = require '../services/image'
WeatherStation = require '../models/weather_station'
config = require '../config'

MAX_UNIQUE_ID_ATTEMPTS = 10

module.exports = class PlaceBaseCtrl
  defaultEmbed: []

  getBySlug: ({slug}, {user}) =>
    @Model.getBySlug slug
    .then (place) =>
      _.defaults {@type}, place
    .then EmbedService.embed {embed: @defaultEmbed}

  search: ({query, sort}, {user}) =>
    @Model.search {query, sort}
    .then (places) =>
      _.map places, (place) =>
        _.defaults {@type}, place
    # .then (results) ->
    #   Promise.map results, EmbedService.embed {embed: defaultEmbed}

  getUniqueSlug: (baseSlug, suffix, attempts = 0) =>
    slug = if suffix \
         then "#{baseSlug}-#{suffix}"
         else baseSlug
    @Model.getBySlug slug
    .then (existingPlace) =>
      if attempts > MAX_UNIQUE_ID_ATTEMPTS
        return "#{baseSlug}-#{Date.now()}"
      if existingPlace
        @getUniqueSlug baseSlug, (suffix or 0) + 1, attempts  + 1
      else
        slug

  deleteByRow: ({row}, {user}) =>
    unless user.username is 'austin'
      router.throw {status: 401, info: 'Unauthorized'}

    @Model.deleteByRow row

  upsert: (options, {user, headers, connection}) =>
    {id, name, location, slug, videos} = options

    matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec location
    unless matches?[0] and matches?[1]
      console.log 'invalid', location
      router.throw {info: 'invalid location', status: 400}
    location = {
      lat: parseFloat(matches[1])
      lon: parseFloat(matches[2])
    }

    videos = _.filter _.map videos, (video) ->
      matches = video?.match(config.YOUTUBE_ID_REGEX)
      youtubeId = matches?[2]
      time = matches?[4]
      if youtubeId
        {sourceType: 'youtube', sourceId: youtubeId, timestamp: time}

    Promise.all [
      (if slug
        Promise.resolve slug
      else
        slug = _.kebabCase(name)
        @getUniqueSlug slug)

      GeocoderService.reverse location
      .catch -> null

      if @Model.SCYLLA_TABLES[0].fields.weather
        WeatherStation.getClosestToLocation location
      else
        Promise.resolve null
    ]
    .then ([slug, address, weatherStation]) =>
      address =
        locality: address?[0]?.city
        administrativeArea: address?[0]?.state

      diff = {slug, name, location, address, videos}
      if weatherStation
        diff.weather = weatherStation.weather

      @Model.upsert diff
      .tap (place) ->
        if place.weather
          ImageService.uploadWeatherImageByPlace place
