
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
  # common between all places
  id: 'timeuuid'
  type: {type: 'text', defaultFn: -> 'custom'} # past, future, custom
  userId: 'uuid'
  name: 'text'
  settings: {type: 'json', defaultFn: -> {privacy: 'public', donut: {isVisible: true, min: 200, max: 300}}} # donut min max, avoidTolls, avoidHighways, privacy (public, private, friend)
  thumbnailPrefix: 'text'
  imagePrefix: 'text' # screenshot of map

  # 'set's don't appear to work with ordering
  # checkInIds: {type: 'list', subType: 'uuid'}

  destinations: {type: 'json', defaultFn: -> []}
  stops: {type: 'json', defaultFn: -> {}}
  routes: {type: 'json', defaultFn: -> []}

  # TODO: destinations / waypoints (aka stops?)
  # destinations: type: 'list', subType: 'text'
  # subtype is json with: {route: {checkInIds: [stops]}, checkInId: ''}

  ###
  deleting checkin deletes both current route, previous check-in's route, and
  has to recreate previous check-in's route...

  could have checkIns and routes as separate columns
  if checkIns change... grab the routes where startCheckInId/endCheckInId changed and update

  routes: [
    {id, startCheckInId, endCheckInId, route, stopCheckInIds, distance, duration}
  ]


  what happens to stops when reordering?
  maybe should be routes instead of destinations?

  routes: type 'list', subType: 'text'

  no?
  ###

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
          clusteringColumns: ['type', 'id']
      }
      {
        name: 'trips_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
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

  getByUserIdAndType: (userId, type, {createIfNotExists} = {}) =>
    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'userId', '=', userId
    .andWhere 'type', '=', type
    .limit 1
    .run {isSingle: true}
    .then (trip) =>
      if createIfNotExists and not trip and type in ['past', 'future']
        @upsert {
          type
          userId
          name: _.startCase type
        }
      else
        trip
    .then @defaultOutput

  _getRouteIdFromDestinations: (startCheckIn, endCheckIn) ->
    # [
    #   startCheckIn.lat, startCheckIn.lon
    #   endCheckIn.lat, endCheckIn.lon
    # ].join ':'
    [
      geohash.encode(startCheckIn.lat, startCheckIn.lon)
      geohash.encode(endCheckIn.lat, endCheckIn.lon)
    ].join ':'

  _replaceCheckIn: (checkIns, checkIn, location, {includeTime} = {}) ->
    checkIns = _.clone(checkIns) or []
    # check if checkIn is already in this trip (eg updating time, location, ...)
    existingIndex = _.findIndex checkIns, {id: checkIn.id}
    if existingIndex isnt -1
      oldCheckIn = checkIns.splice existingIndex, 1

    if includeTime
      insertIndex = _.findLastIndex(checkIns, ({start}) ->
        not checkIn.startTime or checkIn.startTime < start
      ) + 1
    else
      insertIndex = checkIns.length

    shortCheckIn = {
      id: checkIn.id, lat: location.lat, lon: location.lon
    }
    if includeTime
      shortCheckIn.start = checkIn.startTime

    checkIns.splice insertIndex, 0, shortCheckIn
    checkIns

  _buildRoutes: ({existingRoutes, destinations, stops}) =>
    pairs = RoutingService.pairwise destinations
    routes = _.map pairs, ([startCheckIn, endCheckIn]) =>
      id = @_getRouteIdFromDestinations startCheckIn, endCheckIn
      routeStops = [startCheckIn]
      if stops[id]
        routeStops = routeStops.concat stops[id]
      routeStops = routeStops.concat endCheckIn

      console.log 'id', id

      legPairs = RoutingService.pairwise routeStops
      existingRoute = _.find existingRoutes, {id}
      legs = _.map legPairs, ([legStartCheckIn, legEndCheckIn]) =>
        legId = @_getRouteIdFromDestinations legStartCheckIn, legEndCheckIn
        existingLeg = _.find(existingRoute?.legs, {id: legId})
        _.defaults {
          id: legId, startCheckInId: legStartCheckIn.id
          endCheckInId: legEndCheckIn.id
        }, existingLeg

      # if _.isEmpty legs
      #   existingRoute = _.find existingRoutes, {id}
      #   existingLeg = _.find(existingRoute?.legs, {id})
      #   legs.push _.defaults {
      #     id: id
      #     startCheckInId: startCheckIn.id
      #     endCheckInId: endCheckIn.id
      #   }, existingLeg

      {
        id: id
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
          )
        Promise.props leg
      Promise.props route

  _getRoute: (startCheckIn, endCheckIn) ->
    console.log 'get route', startCheckIn, endCheckIn
    RoutingService.getRoute({
      locations: [
        {lat: startCheckIn.lat, lon: startCheckIn.lon}
        {lat: endCheckIn.lat, lon: endCheckIn.lon}
      ]
    }, {includeLegs: true})
    .then (routes) ->
      routes?.legs?[0]

  # gives route legs {lon, lat}
  embedTripRouteLegLocationsByTrip: (trip, tripRoute) ->
    allCheckIns = trip.destinations
    if tripRoute?.id
      allCheckIns = allCheckIns.concat trip.stops[tripRoute.id]

      _.defaults {
        legs: _.map tripRoute.legs, (leg) ->
          _.defaults {
            startCheckIn: _.find allCheckIns, {id: leg.startCheckInId}
            endCheckIn: _.find allCheckIns, {id: leg.endCheckInId}
          }, leg
      }, tripRoute

  upsertStopByRowAndRouteId: (row, routeId, checkIn, location) =>
    stops = row.stops
    console.log 'stops1', row.stops
    # TODO: check if stop exists, if so, update...
    # if not, determineStopIndexAndDetourTimeByTripRoute
    stops[routeId] = @_replaceCheckIn row.stops[routeId], checkIn, location
    @_buildRoutes {destinations: row.destinations, stops}
    .then (routes) =>
      # console.log JSON.stringify routes, null, 2
      console.log 'stops', stops
      @upsertByRow row, {
        routes: routes
        stops: stops
      }

  upsertDestinationByRow: (row, checkIn, location) =>
    console.log 'go...', row.destinations
    destinations = @_replaceCheckIn row.destinations, checkIn, location, {
      includeTime: true
    }
    # console.log destinations
    @_buildRoutes {existingRoutes: row.routes, destinations, stops: row.stops}
    .then (routes) =>
      @upsertByRow row, {
        routes: routes
        destinations: destinations
      }



    # @upsertByRow row, {}, {add: {checkInIds: [[checkInId]]}}


  deleteCheckInIdById: (id, checkInId) =>
    @getById id
    .then (trip) =>
      @upsertByRow trip, {}, {remove: {checkInIds: [checkInId]}}

  defaultInput: (row, options) ->
    row.lastUpdateTime = new Date()
    super row, options

module.exports = new Trip()





# module.exports.upsertStopByRowAndRouteId {
#   destinations: [
#     {id: 'existing-checkin-id', start: new Date(Date.now() - 3600000), lat: 1, lon: 2}
#     {id: 'checkin-id', start: new Date(Date.now() - 1800000), lat: 3, lon: 4}
#   ]
#   stops: {}
#   routes: [
#     {
#       "id": "1:2:3:4",
#       "startCheckInId": "checkin-id",
#       "endCheckInId": "existing-checkin-id",
#       "legs": [
#         {
#           "id": "1:2:3:4"
#           "startCheckInId": "existing-checkin-id"
#           "endCheckInId": "checkin-id"
#           "route":
#             "duration": 1
#             "distance": 1
#             "polyline": "existing-route"
#         }
#       ]
#     }
#   ]
#
# }, '1:2:3:4', {id: 'new-stop-id', startTime: new Date(), endTime: new Date()}, {lat: 5, lon: 6}





# module.exports.upsertDestinationByRow {
#   destinations: [
#     {id: 'existing-checkin-id', start: new Date(Date.now() - 3600000), lat: 1, lon: 2}
#     {id: 'checkin-id', start: new Date(Date.now() - 1800000), lat: 3, lon: 4}
#   ]
#   stops: {}
#   routes: [
#     {
#       "id": "1:2:3:4",
#       "startCheckInId": "checkin-id",
#       "endCheckInId": "existing-checkin-id",
#       "legs": [
#         {
#           "id": "1:2:3:4"
#           "startCheckInId": "existing-checkin-id"
#           "endCheckInId": "checkin-id"
#           "route":
#             "duration": 1
#             "distance": 1
#             "polyline": "existing-route"
#         }
#       ]
#     }
#   ]
#
# }, {id: 'new-checkin-id', startTime: new Date(), endTime: new Date(), lat: 5, lon: 6}
