_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
request = require 'request-promise'
geohash = require 'ngeohash'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
elasticsearch = require '../services/elasticsearch'
RoutingService = require '../services/routing'
config = require '../config'

scyllaFields =
  id: 'timeuuid'
  userId: 'uuid'
  name: 'text'
  settings: {type: 'json', defaultFn: -> {privacy: 'public', rigHeightInches: 13.5 * 12, donut: {isVisible: true, min: 200, max: 300}}} # donut min max, avoidTolls, avoidHighways, privacy (public, private, friend)
  thumbnailPrefix: 'text'
  imagePrefix: 'text' # screenshot of map
  destinations: {type: 'json', defaultFn: -> []} # [{id, lat, lon}]
  stops: {type: 'json'} # {id, lat, lon}
  bounds: {type: 'json'}
  stats: {type: 'json'}
  lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}

class Trip extends Base
  getScyllaTables: ->
    [
      {
        name: 'trips_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
      }
      {
        name: 'trips_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
      {
        name: 'trip_routes_by_tripId'
        ignoreUpsert: true
        keyspace: 'free_roam'
        fields:
          tripId: 'timeuuid'
          routeId: 'text'
          number: 'int'
          startCheckInId: 'uuid'
          endCheckInId: 'uuid'
          bounds: 'json'
          legs: {type: 'json', defaultFn: -> []} # {id, startCheckInId, endCheckInId, route: {time, distance, shape}}
        primaryKey:
          partitionKey: ['tripId']
          clusteringColumns: ['routeId']
      }
    ]

  clearCacheByRow: (row) =>
    userPrefix = CacheService.PREFIXES.TRIPS_GET_ALL_BY_USER_ID
    followingPrefix = CacheService.PREFIXES.TRIPS_GET_ALL_FOLLOWING_BY_USER_ID
    followingCategoryPrefix =
      CacheService.PREFIXES.TRIPS_FOLLOWING_TRIP_ID_CATEGORY

    Promise.all [
      CacheService.deleteByKey "#{userPrefix}:#{row.userId}"
      CacheService.deleteByKey "#{followingPrefix}:#{row.userId}"
      CacheService.deleteByCategory "#{followingCategoryPrefix}:#{row.id}"
    ]

  updateMapByRow: (trip) =>
    imagePrefix = "trips/#{trip.id}_profile"
    console.log "#{config.SCREENSHOTTER_HOST}/screenshot"
    Promise.resolve request "#{config.SCREENSHOTTER_HOST}/screenshot",
      json: true
      qs:
        imagePrefix: imagePrefix
        clipY: 32
        viewportHeight: 424
        width: 600
        height: 360
        # TODO: https
        url: "http://#{config.FREE_ROAM_HOST}/travel-map-screenshot/#{trip.id}"
    .then =>
      @upsertByRow trip, {
        imagePrefix
        lastUpdateTime: new Date()
      }

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput

  getById: (id) =>
    cknex().select '*'
    .from @getScyllaTables()[1].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getAllRoutesByTripId: (tripId) =>
    cknex().select '*'
    .from @getScyllaTables()[2].name
    .where 'tripId', '=', tripId
    .run()
    .then (routes) ->
      _.orderBy routes, 'number'
    .map @defaultRouteOutput

  getRouteByTripIdAndRouteId: (tripId, routeId) =>
    cknex().select '*'
    .from @getScyllaTables()[2].name
    .where 'tripId', '=', tripId
    .andWhere 'routeId', '=', routeId
    .run {isSingle: true}
    .then @defaultRouteOutput

  defaultRouteOutput: (route) ->
    route.bounds = try
      JSON.parse route.bounds
    catch
      {}
    route.legs = try
      JSON.parse route.legs
    catch
      {}
    route

  _getRouteIdFromDestinations: (startCheckIn, endCheckIn) ->
    # [
    #   startCheckIn.lat, startCheckIn.lon
    #   endCheckIn.lat, endCheckIn.lon
    # ].join ':'
    [
      geohash.encode(startCheckIn.lat, startCheckIn.lon)
      geohash.encode(endCheckIn.lat, endCheckIn.lon)
    ].join ':'

  _spliceDestination: (checkIns, checkIn, location) ->
    checkIns = _.clone(checkIns) or []
    # check if checkIn is already in this trip (eg updating time, location, ...)
    existingIndex = _.findIndex checkIns, {id: checkIn.id}
    if existingIndex isnt -1
      oldCheckIn = checkIns.splice existingIndex, 1

    insertIndex = _.findLastIndex(checkIns, ({start}) ->
      not checkIn.startTime or checkIn.startTime >= start
    ) + 1

    shortCheckIn = {
      id: checkIn.id, lat: location.lat, lon: location.lon
      start: checkIn.startTime
    }

    checkIns.splice insertIndex, 0, shortCheckIn
    checkIns

  _spliceStop: (tripRoute, stops, checkIn, location) ->
    stops = _.clone(stops) or []
    # check if checkIn is already in this trip (eg updating time, location, ...)
    existingIndex = _.findIndex stops, {id: checkIn.id}
    if existingIndex isnt -1
      oldCheckIn = stops.splice existingIndex, 1

    insertIndex = stops.length

    checkIn = _.defaults location, checkIn

    RoutingService.determineStopIndexAndDetourTimeByTripRoute tripRoute, checkIn
    .then ({index}) ->

      shortCheckIn = {
        id: checkIn.id, lat: location.lat, lon: location.lon
      }

      stops.splice index, 0, shortCheckIn
      stops

  _buildRoutes: ({destinations, stops, trip}) =>
    destinations ?= trip.destinations
    stops ?= trip.stops
    existingRoutes = trip.routes
    destinations = _.clone destinations
    stops = _.clone stops
    pairs = RoutingService.pairwise destinations
    routes = _.map pairs, ([startCheckIn, endCheckIn], i) =>
      routeId = @_getRouteIdFromDestinations startCheckIn, endCheckIn
      routeStops = [startCheckIn]
      if stops[routeId]
        routeStops = routeStops.concat stops[routeId]
      routeStops = routeStops.concat endCheckIn

      legPairs = RoutingService.pairwise routeStops
      existingRoute = _.find existingRoutes, {routeId}
      legs = _.map legPairs, ([legStartCheckIn, legEndCheckIn]) =>
        legId = @_getRouteIdFromDestinations legStartCheckIn, legEndCheckIn
        existingLeg = _.find(existingRoute?.legs, {legId})
        _.defaults {
          legId, startCheckInId: legStartCheckIn.id
          endCheckInId: legEndCheckIn.id
        }, existingLeg

      {
        routeId: routeId
        number: i + 1
        startCheckInId: startCheckIn.id
        endCheckInId: endCheckIn.id
        legs: legs
      }

    allCheckIns = destinations.concat _.flatten _.values(stops)

    Promise.map routes, (route) =>
      route.legs = Promise.map route.legs, (leg) =>
        unless leg.route
          leg.route = @_getRoute(
            _.find allCheckIns, {id: leg.startCheckInId}
            _.find allCheckIns, {id: leg.endCheckInId}
            {trip}
          )
        Promise.props leg
      Promise.props route
    .map (route) =>
      route.bounds = @_getBoundsFromLegs route.legs
      route

  _getRoute: (startCheckIn, endCheckIn, {trip} = {}) ->
    RoutingService.getRoute({
      locations: [
        {lat: startCheckIn.lat, lon: startCheckIn.lon}
        {lat: endCheckIn.lat, lon: endCheckIn.lon}
      ]
    }, {trip, includeShape: true})

  # gives route legs {lon, lat}
  embedTripRouteLegLocationsByTrip: (trip, tripRoute) ->
    allCheckIns = trip?.destinations
    if tripRoute?.routeId
      allCheckIns = allCheckIns.concat trip.stops[tripRoute.routeId]

      _.defaults {
        legs: _.map tripRoute.legs, (leg) ->
          _.defaults {
            startCheckIn: _.find allCheckIns, {id: leg.startCheckInId}
            endCheckIn: _.find allCheckIns, {id: leg.endCheckInId}
          }, leg
      }, tripRoute

  upsertRoutesByTripId: (tripId, routes) =>
    Promise.map routes, (route) =>
      route.tripId = tripId
      route.legs = JSON.stringify route.legs
      route.bounds = JSON.stringify route.bounds
      @_upsertScyllaRowByTableAndRow @getScyllaTables()[2], route

  deleteRoutesByTripId: (tripId, routes) =>
    Promise.map routes, (route) =>
      console.log 'delete', route
      @_deleteScyllaRowByTableAndRow @getScyllaTables()[2], route

  upsertStopByTripAndTripRoute: (trip, tripRoute, checkIn, location) =>
    stops = trip.stops
    routeId = tripRoute.routeId
    tripRoute = @embedTripRouteLegLocationsByTrip trip, tripRoute
    @_spliceStop tripRoute, stops[routeId], checkIn, location
    .then (newStops) =>
      stops[routeId] = newStops
      @_upsertStopsByTripAndRouteId trip, routeId, stops


  _upsertStopsByTripAndRouteId: (trip, routeId, stops) =>
    @_buildRoutes {
      stops
      trip
    }
    .then (routes) =>
      changedRoutes = _.filter routes, {routeId}

      Promise.all [
        @upsertByRow trip, {
          stops: stops
          bounds: @_getStatsFromRoutes routes
          stats: @_getStatsFromRoutes routes
        }

        @upsertRoutesByTripId trip.id, changedRoutes
      ]

  deleteStopByTripAndTripRoute: (trip, tripRoute, stopId) =>
    index = _.findIndex trip.stops[tripRoute.routeId], {id: stopId}
    trip.stops[tripRoute.routeId].splice index, 1
    stops = trip.stops
    @_upsertStopsByTripAndRouteId trip, tripRoute.routeId, stops

  deleteDestinationByRoutesEmbeddedTrip: (trip, destinationId) =>
    index = _.findIndex trip.destinations, {id: destinationId}
    if index is -1
      console.log 'delete destination id not found', destinationId
      return

    trip.destinations.splice index, 1
    destinations = trip.destinations
    @_upsertDestinationsByTrip trip, destinations

  upsertDestinationByRoutesEmbeddedTrip: (trip, checkIn, location) =>
    destinations = @_spliceDestination trip.destinations, checkIn, location
    @_upsertDestinationsByTrip trip, destinations

  _upsertDestinationsByTrip: (trip, destinations) =>
    @_buildRoutes {
      destinations
      trip
    }
    .then (routes) =>
      changedRoutes = _.filter routes, (route) ->
        not _.find trip.routes, {routeId: route.routeId}

      deletedRoutes = _.filter trip.routes, (route) ->
        not _.find routes, {routeId: route.routeId}

      Promise.all [
        @upsertByRow trip, {
          destinations: destinations
          bounds: @_getBoundsFromRoutes routes
          stats: @_getStatsFromRoutes routes

        }

        @upsertRoutesByTripId trip.id, changedRoutes

        @deleteRoutesByTripId trip.id, deletedRoutes
      ]

  _getBoundsFromRoutes: (routes) ->
    {
      x1: _.minBy(routes, ({bounds}) -> bounds.x1)?.bounds.x1
      y1:_.minBy(routes, ({bounds}) -> bounds.y1)?.bounds.y1
      x2: _.maxBy(routes, ({bounds}) -> bounds.x2)?.bounds.x2
      y2: _.maxBy(routes, ({bounds}) -> bounds.y2)?.bounds.y2
    }


  _getBoundsFromLegs: (legs) ->
    {
      x1: _.minBy(legs, ({route}) -> route?.bounds.x1)?.route?.bounds.x1
      y1:_.minBy(legs, ({route}) -> route?.bounds.y1)?.route?.bounds.y1
      x2: _.maxBy(legs, ({route}) -> route?.bounds.x2)?.route?.bounds.x2
      y2: _.maxBy(legs, ({route}) -> route?.bounds.y2)?.route?.bounds.y2
    }

  _getStatsFromRoutes: (routes) ->
    {
      distance: _.sumBy routes, ({legs}) ->
        _.sumBy legs, ({route}) -> route.distance
      time: _.sumBy routes, ({legs}) ->
        _.sumBy legs, ({route}) -> route.time
    }

  defaultInput: (row, options) ->
    row.lastUpdateTime = new Date()
    super row, options

module.exports = new Trip()
