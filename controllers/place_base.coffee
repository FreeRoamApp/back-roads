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
EmailService = require '../services/email'
PlacesService = require '../services/places'
PlaceReviewService = require '../services/place_review'
WeatherService = require '../services/weather'
config = require '../config'

MAX_UNIQUE_ID_ATTEMPTS = 10

module.exports = class PlaceBaseCtrl
  defaultEmbed: []

  getBySlug: ({slug}, {user}) =>
    @Model.getBySlug slug
    .then (place) =>
      if place
        _.defaults {@type}, place
      else
        console.log 'get', slug
        router.throw {status: 404, info: 'Place not found'}
    .then EmbedService.embed {embed: @defaultEmbed}

  search: ({query, tripId, tripRouteId, sort, limit, includeId}, {user}) =>
    (if tripId
      # limit = 2000 # show them all
      @_updateESQueryFromTripIdAndTripRouteId tripId, tripRouteId, query
    else
      Promise.resolve query
    ).then (query) =>
      @Model.search {query, sort, limit}, {
        outputFn: if includeId
          (place) =>
            id = place.id
            place = @Model.defaultESOutput place
            place.id = id
            place
      }

  _updateESQueryFromTripIdAndTripRouteId: (tripId, tripRouteId, query) ->
    Trip.getById tripId
    .then (trip) ->
      console.log 'trid', tripRouteId
      if tripRouteId
        routes = [_.find trip.routes, {id: tripRouteId}]
      else
        routes = trip.routes
      points = _.flatten _.map routes, (route) ->
        _.flatten _.map route.legs, ({route}) ->
          simplify polyline.decode(route.shape), 0.5

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
      if existingPlace?.id
        @getUniqueSlug baseSlug, (suffix or 0) + 1, attempts  + 1
      else
        slug

  deleteByRow: ({row}, {user}) =>
    # TODO: replace with deleteById and grab the place from DB so people can't
    # mess with incoming data (changing slug/id)
    unless user.username in ['austin', 'big_boxtruck', 'roadpickle', 'rachel']
      router.throw {status: 401, info: 'Unauthorized'}

    @Model.getById row.id
    .then (place) =>
      EmailService.send {
        to: EmailService.EMAILS.EVERYONE
        subject: "Place deleted by #{user.username}"
        text: JSON.stringify place
      }

      @Model.deleteByRow row

  searchNearby: ({location, limit}) =>
    @Model.searchNearby location, {
      limit, distance: 15, outputFn: (place) =>
        id = place.id
        place = @Model.defaultOutput place
        place.id = id
        place
    }

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
      @Model.upsertByRow place, {
        distanceTo
      }

  dedupe: (options, {user}) =>
    unless user.username is 'austin'
      router.throw {
        status: 401
        info: 'Unauthorized'
      }
    {sourceSlug, sourceType, destinationSlug, destinationType} = options
    console.log destinationSlug
    Promise.all [
      PlacesService.getByTypeAndSlug(
        sourceType, sourceSlug
      )
      PlacesService.getByTypeAndSlug(
        destinationType, destinationSlug
      )
    ]
    .then ([source, destination]) =>
      console.log Boolean source
      console.log '------------------------'
      console.log destination
      unless source and destination
        router.throw status: 404, info: 'slug not found'

      @ReviewModel.getAllByParentId source.id
      .map EmbedService.embed {embed: [EmbedService.TYPES.REVIEW.EXTRAS]}
      .map (sourceReview) ->
        console.log sourceReview
        parentDiff = PlaceReviewService.getParentDiff destination, sourceReview.rating
        parentDiffFromExtras = PlaceReviewService.getParentDiffFromExtras {
          parent: destination, extras: sourceReview.extras, operator: 'add'
        }
        console.log parentDiffFromExtras
        parentDiff = _.defaults parentDiff, parentDiffFromExtras
        console.log parentDiff
        # TODO: iterate over sourceReviews, upsert to change parentId
        # PlaceReviewService.getParentDiff
        # PlaceReviewService.getParentDiff


  upsert: (options, {user, headers, connection}) =>
    {id, name, details, location, subType, agencySlug, regionSlug,
      officeSlug, slug, prices} = options

    isUpdate = Boolean id

    matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec location
    unless matches?[0] and matches?[1]
      console.log 'invalid', location
      router.throw {
        status: 400
        info:
          langKey: 'error.invalidCoordinates'
          step: 'initialInfo'
          field: 'location'
      }
    location = {
      lat: parseFloat(matches[1])
      lon: parseFloat(matches[2])
    }

    Promise.all [
      (if id
        @Model.getById id
      else
        Promise.resolve null
      )

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
    .then ([existingPlace, slug, address, weatherStation, cellSignal]) =>
      diff = {slug, name, details, location, address}
      if weatherStation
        diff.weather = weatherStation.weather
      if subType
        diff.subType = subType
      if agencySlug
        diff.agencySlug = agencySlug
      if regionSlug
        diff.regionSlug = regionSlug
      if officeSlug
        diff.officeSlug = officeSlug
      if cellSignal
        cellSignal = _.mapValues cellSignal, (signal, carrier) ->
          {signal, count: 0}
        diff.cellSignal = _.defaults diff.cellSignal, cellSignal

      if prices
        diff.prices = prices
      # else if not isUpdate
      #   diff.prices ?= {all: {mode: 0}} # TODO

      (if existingPlace
        @Model.upsertByRow existingPlace, diff
      else
        @Model.upsert diff
      )
      .tap (place) =>
        Promise.all _.filter [
          if @Model.getScyllaTables()[0].fields.distanceTo
            @_setNearbyAmenities place

          if @Model.getScyllaTables()[0].fields.weather
            WeatherService.getForecastDiff place
            .then (diff) ->
              PlacesService.upsertByTypeAndRow place.type, place, diff
        ]

  # TODO: heavily cache this
  getNearestAmenitiesById: ({id}) =>
    # get closest dump, water, groceries
    @Model.getById id
    .then (place) ->
      Amenity.searchNearby place.location
      .then ({places}) ->
        amenities = places
        commonAmenities = _.filter _.map config.COMMON_AMENITIES, (amenityType) ->
          _.find amenities, ({amenities}) ->
            amenities.indexOf(amenityType) isnt -1
        _.uniqBy commonAmenities, 'id'
