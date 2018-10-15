request = require 'request-promise'
Promise = require 'bluebird'

config = require '../config'

METERS_PER_MILE = 1609.34
ONE_MINUTE_S = 60

# TODO: replace here with own service using osrm or graphhopper
###
osrm might be better if it has better truck / vehicle height support...
graphhopper is faster / uses less memory
graphhopper has this https://github.com/graphhopper/graphhopper/pull/936
will take a ton of time and cpu/memory to preprocess north america for routing

http://download.geofabrik.de/north-america/us/south-dakota-latest.osm.pbf
mv south-dakota-latest.osm.pbf data/europe_germany_berlin.pbf
docker run -i --rm --name graphhopper -v /data:/data -p 8989:8989 -t graphhopper/graphhopper:stable
# ^^ doesn't actually work atm, but it's a start
###
class RoutingService
  constructor: -> null

  # returns {distance: (mi), time: (min)}
  getDistance: (location1, location2) ->
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
