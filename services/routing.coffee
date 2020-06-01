request = require 'request-promise'
Promise = require 'bluebird'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'
geohash = require 'ngeohash'
stringSimilarity = require 'string-similarity'
turf = require '@turf/turf'
# turfBearing = require '@turf/bearing'
turfBuffer = require '@turf/buffer'
require '@turf/nearest-point-on-line'
_ = require 'lodash'
geodist = require 'geodist'

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

    frequency = Math.ceil points.length / (count - 1)

    _.reduce points, (arr, point, i) ->
      if i is 0 or i is points.length - 1 or not (i % frequency)
        arr.push point
      arr
    , []

  distributedSampleByDistance: (points, distance, unit = 'mi') ->
    dist = 0
    _.reduce points, (arr, point, i) ->
      if points[i - 1]
        dist += geodist points[i - 1], point, {unit, exact: true}
      if dist > distance or i is 0 or i is points.length - 1
        dist = 0
        # if includeBearings
        #   if points[i - 1]
        #     bearing = (360 + 270 + (turf.bearing point, points[i - 1])) % 360
        #   else
        #     bearing = ''
        #   arr.push {point, bearing}
        # else
        arr.push point
      arr
    , []

  getElevation: ({location}) ->
    console.log 'req elev'
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
    console.log 'req elev ranges'
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
    locations = polyline.decode(shape, 6).map ([lat, lon]) ->
      {lat: lat, lon: lon}
    # locations =
    @getElevationsRanges {locations}

  _getRouteUncached: ({locations, avoidLocations}, options = {}) =>
    {
      includeShape, attempts, settings
    } = options
    attempts ?= 0

    costing = settings?.costing or 'auto'
    rigHeightInches = settings?.rigHeightInches

    console.log 'req route'
    request 'https://valhalla.freeroam.app/route',
      json: true
      qs:
        json:
          JSON.stringify {
            directions_type: if includeShape then 'maneuvers' else 'none'
            locations: locations
            avoid_locations: avoidLocations
            costing: costing
            costing_options:
              auto:
                country_crossing_penalty: 2000
                use_highways: not settings?.avoidHighways
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
        if attempts < 3 and rigHeightInches
          console.log 'check low clearances'
          routePoints = _.flatten _.map route.trip.legs, (leg) ->
            points = polyline.decode leg.shape, 6
          routePromise = @_checkForLowClearances routePoints, {
            rigHeightInches, route
          }
          .then (lowClearances) =>
            console.log lowClearances
            if not _.isEmpty lowClearances
              console.log 'retry'
              avoidLocations = _.map lowClearances, 'location'
              # FIXME: work for more than 50 low clearances
              avoidLocations = _.take avoidLocations, 50
              @_getRouteUncached {locations, avoidLocations}, _.defaults({
                attempts: attempts + 1
              }, options)
            else
              route
      routePromise


  # only works w/ 2 locations since it doesn't return legs
  getRoute: ({locations, avoidLocations}, options = {}) =>
    {preferCache, includeShape, attempts, settings} = options
    preferCache ?= true

    # if settings?.waypoints
    #   # inject at index 1
    #   locations.splice.apply locations, [1, 0].concat settings.waypoints

    get = =>
      @_getRouteUncached {locations, avoidLocations}, options
      .then (route) =>
        response = {
          time: route.trip.summary.time
          distance: route.trip.summary.length
        }
        if includeShape and not _.isEmpty route.trip.legs
          points = _.flatten _.map route.trip.legs, (leg) =>
            polyline.decode leg.shape, 6
          response.shape = polyline.encode points, 6
          response.maneuvers = @_getManeuversFromRoute route
          response.bounds =
            x1: route.trip.summary.min_lon
            y1: route.trip.summary.min_lat
            x2: route.trip.summary.max_lon
            y2: route.trip.summary.max_lat
        response

    if preferCache
      key = CacheService.PREFIXES.ROUTING_ROUTE
      key += @generateRouteSlug {locations, avoidLocations, settings}
      if includeShape
        key += '-withshape'
      CacheService.preferCache key, get, {expireSeconds: ONE_HOUR_S}
    else
      get()

  generateRouteSlug: ({locations, avoidLocations, settings}) ->
    locations ?= []
    avoidLocations ?= []
    JSON.stringify {locations, avoidLocations, settings}

  getRouteByRouteSlug: (slug, {includeShape} = {}) =>
    {locations, avoidLocations, settings} = JSON.parse slug
    @getRoute {locations, avoidLocations}, {settings, includeShape}

  _getManeuversFromRoute: (route) ->
    shapeIndex = 0
    # since we're combining maneuvers we need to update the shape indexes
    _.flatten _.map route.trip.legs, (leg) ->
      maneuvers = _.map leg.maneuvers, (maneuver) ->
        maneuver.begin_shape_index += shapeIndex
        maneuver.end_shape_index += shapeIndex
        maneuver
      points = polyline.decode leg.shape, 6
      shapeIndex += points.length
      maneuvers

  _checkForLowClearances: (points, {rigHeightInches, route}) =>
    rigHeightInches ?= 13.5 * 12 # inches
    points = _.map points, ([lon, lat]) -> [lat, lon]
    if points.length >= 2
      line = turf.lineString points
      turfPolygon = turfBuffer line, '0.003', {units: 'miles'}
      # polygon = simplify _.flatten(turfPolygon.geometry.coordinates), 0.1
      polygon = _.flatten(turfPolygon.geometry.coordinates)
      query = {
        bool:
          filter: [
            {geo_polygon: {location: points: polygon}}
            {range: 'data.heightInches': lte: rigHeightInches}
          ]
      }
      Hazard.search {query}, {outputFn: (hazard) -> hazard}
      .then (lowClearances) =>
        # try to filter out if it's the road below the road we're on or no
        # since we're combining maneuvers we need to update the shape indexes
        maneuvers = @_getManeuversFromRoute route
        _.filter lowClearances.places, (lowClearance) ->
          nearestPoint = turf.nearestPointOnLine line, [lowClearance.location.lon, lowClearance.location.lat]
          nearestIndex = nearestPoint.properties.index
          nearestManeuver = _.find maneuvers, (maneuver) ->
            nearestIndex >= maneuver.begin_shape_index and
              nearestIndex < maneuver.end_shape_index
          unless nearestManeuver
            # FIXME: nearestIndex too high...
            console.log 'no maneuver', nearestIndex, JSON.stringify maneuvers, null, 2
          nearestManeuverStreets = nearestManeuver.street_names
          road = lowClearance.data.road
          roadLC = road?.replace(/(\s|-)/g,'').toLowerCase()
          isRoadMatch = not road or _.some nearestManeuverStreets, (nearestStreet) ->
            nearestStreetLC = nearestStreet.replace(/(\s|-)/g,'').toLowerCase()
            isGhettoMatch = nearestStreetLC.indexOf(roadLC) isnt -1 or
              roadLC.indexOf(nearestStreetLC) isnt -1
            similarity = stringSimilarity.compareTwoStrings(
              nearestStreetLC, roadLC
            )
            isGhettoMatch or similarity > 0.7

          isValid = lowClearance.data.isUnderNonRoad or
                      lowClearance.data.type is 'tunnel' or isRoadMatch
          isValid

  determineStopIndexAndDetourTimeByTripRoute: (route, stop, options = {}) =>
    prefix = CacheService.PREFIXES.ROUTE_STOP_INDEX
    hash = geohash.encode stop.lat, stop.lon
    key = "#{prefix}:#{_.map(route.legs, 'legId').join(',')}:#{hash}:#{options.getRoute}"
    CacheService.preferCache key, =>
      # TODO: use turf (nearest-point-on-line?) to reduce number of
      # legs we iterate over (just use ones nearby)
      Promise.map route.legs, (leg, index) =>
        @getDetourTimeByTripRouteAndStop leg, stop, options
        .then ({detour, route}) ->
          {index, detour, route}
      .then (detours) ->
        _.minBy detours, ({detour}) -> detour.time
    , {expireSeconds: ONE_HOUR_S}

  getDetourTimeByTripRouteAndStop: (leg, stop, options = {}) ->
    {getRoute, avoidLocations, settings} = options
    # TODO: get distance from route line, and compare against other stops'
    # distance from route line to find where in
    locations = [
      {lat: leg.startCheckIn.lat, lon: leg.startCheckIn.lon}
      {lat: stop.lat, lon: stop.lon}
      {lat: leg.endCheckIn.lat, lon: leg.endCheckIn.lon}
    ]
    slug = @generateRouteSlug {locations, avoidLocations, settings}
    @getRouteByRouteSlug slug, {includeShape: getRoute}
    .then (route) ->
      # FIXME: for some reason leg.route is slower.
      # maybe because it goes through a custom point? and the detourTime doesn't (it needs to)
      # console.log route
      # console.log 'vs'
      # console.log leg.route
      obj = {
        detour:
          time: route.time - leg.route.time
          distance: route.distance - leg.route.distance
      }
      if getRoute
        obj.route = route
      obj

module.exports = new RoutingService()
