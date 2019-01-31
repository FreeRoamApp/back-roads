Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'
turf = require '@turf/turf'
turfBuffer = require '@turf/buffer'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'

EmbedService = require '../services/embed'
GeocoderService = require '../services/geocoder'
ImageService = require '../services/image'
CellSignalService = require '../services/cell_signal'
EmbedService = require '../services/embed'
RoutingService = require '../services/routing'
Amenity = require '../models/amenity'
Trip = require '../models/trip'
WeatherStation = require '../models/weather_station'
config = require '../config'

MAX_UNIQUE_ID_ATTEMPTS = 10

module.exports = class PlaceBaseCtrl
  defaultEmbed: []

  getBySlug: ({slug}, {user}) =>
    @Model.getBySlug slug
    .then (place) =>
      if place
        _.defaults {@type}, place
    .then EmbedService.embed {embed: @defaultEmbed}

  search: ({query, tripId, sort, limit}, {user}) =>
    (if tripId
      # limit = 2000 # show them all
      @_updateESQueryFromTripId tripId, query
    else
      Promise.resolve query
    ).then (query) =>
      @Model.search {query, sort, limit}

  _updateESQueryFromTripId: (tripId, query) ->
    Trip.getById tripId
    .then EmbedService.embed {embed: [EmbedService.TYPES.TRIP.CHECK_INS]}
    .then EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTE]}
    .then (trip) ->
      points = _.flatten _.map trip.route.legs, ({shape}) ->
        simplify polyline.decode(shape), 0.5

      points = _.map points, ([lon, lat]) -> [lat / 10, lon / 10]
      line = turf.lineString points
      turfPolygon = turfBuffer line, '20', {units: 'miles'}
      polygon = simplify _.flatten(turfPolygon.geometry.coordinates), 0.1

      # topRight = _.map points, ([lat, lon]) ->
      #   [lon / 10 + 0.5, lat / 10 + 0.5]
      # bottomLeft = _.map(points, ([lat, lon]) ->
      #   [lon / 10 - 0.5, lat / 10 - 0.5]).reverse() # reverse so we can get a continue line to draw polygon
      # polygon = topRight.concat bottomLeft

      query.bool.filter.push {geo_polygon: {location: points: polygon}}
      query

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

      if @Model.getScyllaTables()[0].fields.address
        GeocoderService.reverse location
        .catch -> null
      else
        Promise.resolve null

      if @Model.getScyllaTables()[0].fields.weather
        WeatherStation.getClosestToLocation location
      else
        Promise.resolve null

      if not isUpdate and @Model.getScyllaTables()[0].fields.cellSignal
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

      diff.prices ?= {all: {mode: 0}} # TODO

      console.log 'upsert', diff

      @Model.upsert diff
      .tap (place) =>
        if @Model.getScyllaTables()[0].fields.distanceTo
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
