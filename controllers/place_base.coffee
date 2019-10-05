Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'
turf = require '@turf/turf'
turfBuffer = require '@turf/buffer'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'

Amenity = require '../models/amenity'
LocalMap = require '../models/local_map'
PlaceAttachment = require '../models/place_attachment_base'
Trip = require '../models/trip'
WeatherStation = require '../models/weather_station'
EmbedService = require '../services/embed'
GeocoderService = require '../services/geocoder'
ImageService = require '../services/image'
CellSignalService = require '../services/cell_signal'
EmbedService = require '../services/embed'
RoutingService = require '../services/routing'
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

  search: ({query, tripId, tripRouteId, tripAltRouteSlug, sort, limit, includeId}, {user}) =>
    (if tripId and tripRouteId
      # limit = 2000 # show them all
      @_updateESQueryFromTrip tripId, tripRouteId, tripAltRouteSlug, query
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

  _updateESQueryFromTrip: (tripId, tripRouteId, tripAltRouteSlug, query) ->
    Promise.all [
      Trip.getRouteByTripIdAndRouteId tripId, tripRouteId
      if tripAltRouteSlug
        RoutingService.getRouteByRouteSlug tripAltRouteSlug, {
          includeShape: true
        }
    ]
    .then ([route, altRoute]) ->
      should = []

      points = _.flatten _.map route.legs, ({route}) ->
        simplify polyline.decode(route.shape, 6), 0.1

      points = _.map points, ([lon, lat]) -> [lat, lon]
      if points.length >= 2
        line = turf.lineString points
        turfPolygon = turfBuffer line, '10', {units: 'miles'}
        polygon = _.flatten(turfPolygon.geometry.coordinates)
        should.push {geo_polygon: {location: points: polygon}}

      if altRoute
        points = simplify polyline.decode(altRoute.shape, 6), 0.1
        points = _.map points, ([lon, lat]) -> [lat, lon]
        if points?.length >= 2
          line = turf.lineString points
          turfPolygon = turfBuffer line, '10', {units: 'miles'}
          polygon = _.flatten(turfPolygon.geometry.coordinates)
          should.push {geo_polygon: {location: points: polygon}}

      query.bool.filter.push {bool: {should}}
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
      EmailService.queueSend {
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
          obj[closestAmenity.id] = RoutingService.getRoute(
            {locations: [place.location, closestAmenity.location]}
          )
          .then (route) ->
            {distance: route.distance, time: route.time}
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

  changeType: ({sourceSlug, sourceType, destinationType}, {user}) =>
    unless user.username in ['austin', 'roadpickle', 'big_boxtruck', 'vanwldr']
      router.throw {
        status: 401
        info: 'Unauthorized'
      }

    if sourceType is destinationType
      router.throw {
        status: 400
        info: 'Must be different type'
      }

    PlacesService.getByTypeAndSlug(
      sourceType, sourceSlug
    )
    .then (source) =>
      unless source?.slug
        router.throw status: 404, info: 'slug not found'
      # recreate w/ new type, then @dedupe
      newDestination = _.defaults {type: destinationType}, source
      PlacesService.upsertByTypeAndRow destinationType, null, newDestination
      .then (destination) =>
        @dedupe {
          sourceSlug, sourceType
          destinationType, destinationSlug: destination.slug
          preserveCounts: true
        }, {user}

  dedupe: (options, {user}) =>
    unless user.username in ['austin', 'roadpickle', 'big_boxtruck', 'vanwldr']
      router.throw {
        status: 401
        info: 'Unauthorized'
      }

    {sourceSlug, sourceType, destinationSlug,
      destinationType, preserveCounts} = options

    Promise.all [
      PlacesService.getByTypeAndSlug(
        sourceType, sourceSlug
      )
      PlacesService.getByTypeAndSlug(
        destinationType, destinationSlug
      )
    ]
    .then ([source, destination]) =>
      unless source and destination
        router.throw status: 404, info: 'slug not found'

      PlacesService.getReviewsByTypeAndId sourceType, source.id
      .map EmbedService.embed {embed: [EmbedService.TYPES.REVIEW.EXTRAS]}
      .then (sourceReviews) ->
        EmailService.queueSend {
          to: EmailService.EMAILS.EVERYONE
          subject: "Place dedupe by #{user.username}"
          text: """
#{JSON.stringify source}

---

#{JSON.stringify destination}

---

#{JSON.stringify sourceReviews}
"""
        }
        .then ->
          Promise.each sourceReviews, (sourceReview) ->
            newReview = _.defaults {
              type: "#{destinationType}Review"
              parentId: destination.id
            }, sourceReview

            console.log 'newreview', newReview

            PlaceReviewService.deleteByParentTypeAndId(
              source.type, sourceReview.id, {hasPermission: true, preserveCounts}
            )
            .then ->
              PlaceReviewService.upsertByParentType destination.type, newReview, {
                userId: sourceReview.userId, preserveCounts
              }
          .then ->
            PlacesService.deleteByTypeAndRow source.type, source



          # console.log '-------'
          # console.log 'source review', sourceReview
          # sourceReview.extras?.id = "#{sourceReview.extras.id}"
          # parentDiff = PlaceReviewService.getParentDiff destination, sourceReview.rating
          # parentDiffFromExtras = PlaceReviewService.getParentDiffFromExtras {
          #   parent: destination, extras: sourceReview.extras, operator: 'add'
          # }
          # console.log '-------'
          # # console.log 'parentdiffextras', parentDiffFromExtras
          # parentDiff = _.defaults parentDiff, parentDiffFromExtras
          # console.log '-------'
          # console.log 'parentdiff', parentDiff
          # newReview = _.defaults {
          #   type: "#{destinationType}Review"
          #   parentId: destination.id
          # }, sourceReview
          # # TODO: attachments, reviewExtras, delete old attachments/extras
          # PlaceReviewService.upsertByTypeAndRow(
          #   "#{destinationType}Review", null, newReview
          # )
          # .then ->
          #   Promise.all [
          #     PlacesService.upsertByTypeAndRow(
          #       destinationType, destination, parentDiff
          #     )
          #     PlacesService.deleteByTypeAndRow sourceType, source
          #     PlaceReviewService.deleteByTypeAndRow(
          #       "#{sourceType}Review", sourceReview
          #     )
          #   ]


  upsert: (options, {user, headers, connection}) =>
    {id, name, details, location, subType, agencySlug, regionSlug,
      officeSlug, slug, features, prices} = options

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
      if features
        diff.features = _.reduce features, (obj, feature) ->
          obj[feature] = true
          obj
        , {}
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

      console.log 'diff', diff

      if id
        EmailService.queueSend {
          to: EmailService.EMAILS.EVERYONE
          subject: "Place updated by #{user.username}"
          text: """
#{JSON.stringify existingPlace}

---

#{JSON.stringify diff}
"""
        }

      (if existingPlace
        @Model.upsertByRow existingPlace, diff, {userId: user.id}
      else
        diff.userId = user.id
        @Model.upsert diff, {userId: user.id, isCreate: true}
      )
      .tap (place) =>
        Promise.all _.filter [
          if @Model.getScyllaTables()[0].fields.distanceTo
            @_setNearbyAmenities place

          if @Model.getScyllaTables()[0].fields.weather
            WeatherService.getForecastDiff place
            .then (diff) ->
              PlacesService.upsertByTypeAndRow place.type, place, diff
            .catch ->
              console.log 'forecast fetch failure'
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

  _getAddStopInfo: (trip, tripRoute, place) ->
    unless tripRoute?.legs?[0]
      return Promise.resolve null
    # TODO: these settings are set in a bunch of places, should keep it DRY
    console.log 'triproute', tripRoute?.settings
    settings = _.defaults tripRoute?.settings, trip?.settings
    settings = _.defaults {
      costing: if settings?.useTruckRoute then 'truck' else 'auto'
    }, settings
    RoutingService.determineStopIndexAndDetourTimeByTripRoute(
      tripRoute, place.location, {settings}
    )
    .then ({index, detour}) ->
      RoutingService.getRoute {
        locations: [
          {
            lat: tripRoute.legs[index].startCheckIn.lat
            lon: tripRoute.legs[index].startCheckIn.lon
          }
          place.location
        ]
      }
      .then (fromLastStop) ->
        {fromLastStop, detour}

  _getAddDestinationInfo: (trip, place) ->
    lastDestination = _.last trip.destinations

    unless lastDestination
      return Promise.resolve null

    RoutingService.getRoute {
      locations: [
        {
          lat: lastDestination.lat
          lon: lastDestination.lon
        }
        place.location
      ]
    }
    .then (fromLastStop) ->
      {fromLastStop}


  getSheetInfo: ({place, tripId, tripRouteId}) =>
    # console.log place, tripId, tripRouteId
    Promise.all [
      if place.type is 'coordinate'
        RoutingService.getElevation {location: place.location}
      else
        Promise.resolve null

      if place.type is 'coordinate'
        LocalMap.getAllByLocationInPolygon place.location
      else
        Promise.resolve null

      # FeatureLookupService.getFeaturesByLocation _.defaults {file}, location

      PlacesService.getAttachmentsByTypeAndId place.type, place.id
      .then (attachments) ->
        # there are some images where type is empty instead of 'image'
        _.filter attachments, ({type}) -> type isnt 'video'

      if tripId
        Trip.getById tripId
      else
        Promise.resolve null

      if tripRouteId
        Trip.getRouteByTripIdAndRouteId tripId, tripRouteId
      else
        Promise.resolve null
    ]
    .then ([elevation, localMaps, placeAttachments, trip, tripRoute]) =>
      attachments = _.take(placeAttachments, 5)

      tripRoute = Trip.embedTripRouteLegLocationsByTrip trip, tripRoute
      (if trip and tripRoute
        # FIXME FIXME: cap amount of stops we look at
        @_getAddStopInfo trip, tripRoute, place
      else if not _.isEmpty trip
        @_getAddDestinationInfo trip, place
      else
        Promise.resolve null
      ).then (addStopInfo) ->
        {elevation, localMaps, addStopInfo, attachments}
