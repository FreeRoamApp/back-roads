request = require 'request-promise'
Promise = require 'bluebird'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'
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
    {preferCache, includeLegs, attempts, rigHeightInches, costing} = options
    attempts ?= 0
    costing ?= 'auto'

    console.log costing

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
                use_highways: if costing is 'truck' then 1 else 0
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
      if includeLegs
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


  getRoute: ({locations, avoidLocations,}, options = {}) =>
    {preferCache, includeLegs, attempts, costing} = options
    preferCache ?= true
    costing ?= 'auto'

    get = =>
      @_getRouteUncached {locations, avoidLocations, costing}, options
      .then (route) ->
        console.log 'got route', route
        response = {
          time: route.trip.summary.time
          distance: route.trip.summary.length
        }
        response.legs = _.map route.trip.legs, (leg) ->
          points = polyline.decode leg.shape
          # ~ 10x reduction in size
          shape = polyline.encode simplify(points, 0.01)
          {
            shape: shape
            time: leg.summary.time
            distance: leg.summary.length
          }

        response

    if preferCache
      key = CacheService.PREFIXES.ROUTING_ROUTE + JSON.stringify(locations)
      key += "-#{costing}"
      if includeLegs
        key += '-withlegs'
      CacheService.preferCache key, get, {expireSeconds: ONE_HOUR_S}
    else
      get()

  _checkForLowClearances: (points, {rigHeightInches}) ->
    console.log 'p', points.length
    rigHeightInches ?= 14 * 12 # inches
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
      console.log query
      Hazard.search {query}
      .then (lc) ->
        console.log 'lc', lc
        lc

  determineStopIndexAndDetourTimeByTripRoute: (route, stop) =>
    # TODO: use turf (nearest-point-on-line?) to reduce number of
    # legs we iterate over (just use ones nearby)
    Promise.map route.legs, (leg, index) =>
      @getDetourTimeByTripRouteAndStop leg, stop
      .then (detourTime) ->
        console.log index, detourTime
        {index, detourTime}
    .then (detourTimes) ->
      _.minBy detourTimes, 'detourTime'

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
      console.log arguments[0], {time: leg.route.time, distance: leg.route.distance}
      time - leg.route.time

module.exports = new RoutingService()
