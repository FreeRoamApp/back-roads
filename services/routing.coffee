request = require 'request-promise'
Promise = require 'bluebird'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'
geohash = require 'ngeohash'
turf = require '@turf/turf'
turfBuffer = require '@turf/buffer'
_ = require 'lodash'

CacheService = require './cache'
Hazard = require '../models/hazard'
config = require '../config'

METERS_PER_MILE = 1609.34
FT_PER_METER = 3.28084
ONE_HOUR_S = 3600
ONE_MINUTE_S = 60


# TODO: replace here with own service using valhalla
###
should be able to set height when picking route. also has it for sharp turns, etc...
initially should just use truck route, but can customize later
https://github.com/valhalla/valhalla/blob/63bfd80090e8722bb6e8abc0242262196b191848/src/sif/truckcost.cc
constexpr float kDefaultTruckHeight = 4.11f;   // Meters (13 feet 6 inches)
pbf_costing_options->set_height(kDefaultTruckHeight);

###

class RoutingService
  constructor: -> null

  pairwise: (arr) ->
    unless arr
      return []
    newArr = []
    i = 0
    while i < arr.length - 1
      newArr.push [arr[i], arr[i + 1]]
      i += 1
    newArr

  distributedSample: (points, count) ->
    if points.length < count
      return points

    frequency = Math.floor points.length / (count - 1)

    _.reduce points, (arr, point, i) ->
      if i is 0 or i is points.length - 1 or not (i % frequency)
        arr.push point
      arr
    , []

  getElevation: ({location}) ->
    request 'https://valhalla.freeroam.app/height',
      json: true
      qs:
        json:
          JSON.stringify {
            shape: [
              location
            ]
          }
    .then ({height}) -> Math.round height[0] * FT_PER_METER

  getElevationsRanges: ({locations}) ->
    request 'https://valhalla.freeroam.app/height',
      json: true
      qs:
        json:
          JSON.stringify {
            shape: locations
            range: true
          }
    .then ({range_height}) ->
      _.map range_height, ([range, height]) ->
        [
          range
          Math.round height * FT_PER_METER
        ]

  getElevationsFromPolyline: (shape) =>
    locations = polyline.decode(shape).map ([lat, lon]) ->
      {lat: lat / 10, lon: lon / 10}
    # locations =
    @getElevationsRanges {locations}
    .tap (e) ->
      console.log e

  _getRouteUncached: ({locations, avoidLocations}, options = {}) =>
    {
      preferCache, includeShape, attempts, costing, trip
      avoidHighways
    } = options
    attempts ?= 0
    costing ?= if trip?.settings?.useTruckRoute then 'truck' else 'auto'
    rigHeightInches = trip?.settings?.rigHeightInches
    avoidHighways ?= trip?.settings?.avoidHighways

    request 'https://valhalla.freeroam.app/route',
      json: true
      qs:
        json:
          JSON.stringify {
            narrative: false
            locations: locations
            avoid_locations: avoidLocations
            costing: costing
            costing_options:
              auto:
                country_crossing_penalty: 2000
                use_highways: not avoidHighways
            directions_options:
              units: 'miles'
          }
    .catch (err) ->
      console.log 'routing error', err
      throw err
    .then (route) =>
      unless route?.trip
        return null
      routePromise = Promise.resolve route
      if includeShape
        if attempts < 3
          console.log 'check low clearances'
          routePoints = _.flatten _.map route.trip.legs, (leg) ->
            points = polyline.decode leg.shape
          routePromise = @_checkForLowClearances routePoints, {rigHeightInches}
          .then (lowClearances) =>
            if lowClearances?.total
              console.log 'retry'
              avoidLocations = _.map lowClearances.places, 'location'
              @_getRouteUncached {locations, avoidLocations}, _.defaults({
                attempts: attempts + 1
              }, options)
            else
              route
      routePromise


  # only works w/ 2 locations since it doesn't return legs
  getRoute: ({locations, avoidLocations}, options = {}) =>
    {preferCache, includeShape, attempts, costing} = options
    preferCache ?= true
    costing ?= 'auto'

    get = =>
      @_getRouteUncached {locations, avoidLocations, costing}, options
      .then (route) ->
        leg = route.trip.legs?[0]
        response = {
          time: route.trip.summary.time
          distance: route.trip.summary.length
        }
        if includeShape and leg
          points = polyline.decode leg.shape
          # ~ 10x reduction in size, but the routes it generates will be
          # off since the points might be on other roads
          response.shape = polyline.encode points # simplify(points, 0.01)
          response.bounds =
            x1: leg.summary.min_lon
            y1: leg.summary.min_lat
            x2: leg.summary.max_lon
            y2: leg.summary.max_lat
        response

    if preferCache
      key = CacheService.PREFIXES.ROUTING_ROUTE + JSON.stringify(locations)
      key += "-#{costing}"
      if includeShape
        key += '-withshape'
      CacheService.preferCache key, get, {expireSeconds: ONE_HOUR_S}
    else
      get()

  _checkForLowClearances: (points, {rigHeightInches}) ->
    rigHeightInches ?= 13.5 * 12 # inches
    points = _.map points, ([lon, lat]) -> [lat / 10, lon / 10]
    if points.length >= 2
      line = turf.lineString points
      turfPolygon = turfBuffer line, '0.005', {units: 'miles'}
      # polygon = simplify _.flatten(turfPolygon.geometry.coordinates), 0.1
      polygon = _.flatten(turfPolygon.geometry.coordinates)
      query = {
        bool:
          filter: [
            {geo_polygon: {location: points: polygon}}
            {range: 'data.heightInches': lte: rigHeightInches}
          ]
      }
      Hazard.search {query}

  determineStopIndexAndDetourTimeByTripRoute: (route, stop) =>
    prefix = CacheService.PREFIXES.ROUTE_STOP_INDEX
    hash = geohash.encode stop.lat, stop.lon
    key = "#{prefix}:#{_.map(route.legs, 'legId').join(',')}:#{hash}"
    CacheService.preferCache key, =>
      # TODO: use turf (nearest-point-on-line?) to reduce number of
      # legs we iterate over (just use ones nearby)
      Promise.map route.legs, (leg, index) =>
        @getDetourTimeByTripRouteAndStop leg, stop
        .then (detourTime) ->
          {index, detourTime}
      .then (detourTimes) ->
        _.minBy detourTimes, 'detourTime'
    , {expireSeconds: ONE_HOUR_S}

  getDetourTimeByTripRouteAndStop: (leg, stop) ->
    # TODO: get distance from route line, and compare against other stops'
    # distance from route line to find where in
    @getRoute {
      locations: [
        {lat: leg.startCheckIn.lat, lon: leg.startCheckIn.lon}
        {lat: stop.lat, lon: stop.lon}
        {lat: leg.endCheckIn.lat, lon: leg.endCheckIn.lon}
      ]
    }
    .then ({time}) ->
      time - leg.route.time

module.exports = new RoutingService()
