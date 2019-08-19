request = require 'request-promise'
Promise = require 'bluebird'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'
_ = require 'lodash'

CacheService = require './cache'
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

  # TODO: use {lat, lon} instead of [lon, lat]
  getElevation: ({location}) ->
    request 'https://valhalla.freeroam.app/height',
      json: true
      qs:
        json:
          JSON.stringify {
            shape: [
              {lat: location[1], lon: location[0]}
            ]
          }
    .then ({height}) -> Math.round height[0] * FT_PER_METER

  getRoute: ({locations}, {preferCache} = {}) ->
    preferCache ?= true

    get = ->
      request 'https://valhalla.freeroam.app/route',
        json: true
        qs:
          json:
            JSON.stringify {
              narrative: false
              locations: locations
              costing: 'auto'
              costing_options:
                auto:
                  country_crossing_penalty: 2000
              directions_options:
                units: 'miles'
            }
      .then (route) ->
        unless route?.trip
          return null
        {
          time: route.trip.summary.time
          distance: route.trip.summary.length
          legs: _.map route.trip.legs, (leg) ->
            points = polyline.decode leg.shape
            # ~ 10x reduction in size
            shape = polyline.encode simplify(points, 0.01)
            {
              shape: shape
              time: leg.summary.time
              distance: leg.summary.length
            }
        }

    if preferCache
      key = CacheService.PREFIXES.ROUTING_ROUTE + JSON.stringify(locations)
      CacheService.preferCache key, get, {expireSeconds: ONE_HOUR_S}
    else
      get()

  # returns {distance: (mi), time: (min)}
  getDistance: (location1, location2) ->
    # FIXME: use own routing
    request 'https://route.api.here.com/routing/7.2/calculateroute.json', {
      json: true
      qs:
        app_id: config.HERE.APP_ID
        app_code: config.HERE.APP_CODE
        waypoint0: "geo!#{location1.lat},#{location1.lon}"
        waypoint1: "geo!#{location2.lat},#{location2.lon}"
        metricSystem: 'imperial'
        mode: 'fastest;car;traffic:disabled'
    }
    .then (response) ->
      {distance, baseTime} = response?.response?.route?[0]?.summary or {}
      distance = Math.round( 100 * distance / METERS_PER_MILE) / 100
      time = Math.round(baseTime / ONE_MINUTE_S)
      {distance, time}


module.exports = new RoutingService()
