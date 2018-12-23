Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EmbedService = require '../services/embed'
GeocoderService = require '../services/geocoder'
ImageService = require '../services/image'
CellSignalService = require '../services/cell_signal'
RoutingService = require '../services/routing'
Amenity = require '../models/amenity'
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

  search: ({query, sort, limit}, {user}) =>
    @Model.search {query, sort, limit}

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

  _setNearbyAmenities: (place) =>
    Amenity.searchNearby place.location
    .then ({places, total}) =>
      amenities = places
      unless amenities
        return
      closestAmenities = _.map config.COMMON_AMENITIES, (amenityType) ->
        _.find amenities, ({amenities}) ->
          amenities.indexOf(amenityType) isnt -1
      Promise.props _.reduce closestAmenities, (obj, closestAmenity) ->
        if closestAmenity
          obj[closestAmenity.id] = RoutingService.getDistance(
            place.location, closestAmenity.location
          )
        obj
      , {}
      .then (distances) ->
        _.reduce config.COMMON_AMENITIES, (obj, amenityType, i) ->
          amenity = closestAmenities[i]
          unless amenity
            return obj
          distance = distances[amenity.id]
          if amenity and distance
            obj[amenityType] = _.defaults distance, {id: amenity.id}
          obj
        , {}
    .then (distanceTo) =>
      @Model.upsert {
        id: place.id
        slug: place.slug
        distanceTo
      }

  upsert: (options, {user, headers, connection}) =>
    {id, name, location, subType, slug, videos} = options

    isUpdate = Boolean id

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

      if @Model.SCYLLA_TABLES[0].fields.address
        GeocoderService.reverse location
        .catch -> null
      else
        Promise.resolve null

      if @Model.SCYLLA_TABLES[0].fields.weather
        WeatherStation.getClosestToLocation location
      else
        Promise.resolve null

      if not isUpdate and @Model.SCYLLA_TABLES[0].fields.cellSignal
        CellSignalService.getEstimatesByLocation location
        .catch ->
          console.log 'cell estimation error'
    ]
    .then ([slug, address, weatherStation, cellSignal]) =>
      diff = {slug, name, location, address, videos}
      if weatherStation
        diff.weather = weatherStation.weather
      if subType
        diff.subType = subType
      if cellSignal
        cellSignal = _.mapValues cellSignal, (signal, carrier) ->
          {signal, count: 0}
        diff.cellSignal = _.defaults diff.cellSignal, cellSignal

      console.log 'upsert', diff

      @Model.upsert diff
      .tap (place) =>
        if @Model.SCYLLA_TABLES[0].fields.distanceTo
          @_setNearbyAmenities place

        if place.weather
          ImageService.uploadWeatherImageByPlace place

  # TODO: heavily cache this
  getNearestAmenitiesById: ({id}) =>
    # get closest dump, water, groceries
    @Model.getById id
    .then (place) ->
      Amenity.searchNearby place.location
      .then ({places}) ->
        amenities = places
        _.filter _.map config.COMMON_AMENITIES, (amenityType) ->
          _.find amenities, ({amenities}) ->
            amenities.indexOf(amenityType) isnt -1
