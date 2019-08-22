_ = require 'lodash'
Promise = require 'bluebird'

Amenity = require '../models/amenity'
BaseMessage = require './base_message'
Campground = require '../models/campground'
CheckIn = require '../models/check_in'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
PlacesService = require '../services/places'
RoutingService = require '../services/routing'

class TripEmbed
  user: (trip) ->
    if trip.userId
      BaseMessage.user {
        userId: trip.userId
      }

  destinationsInfo: (trip) ->
    # TODO: cache as a whole and maybe per checkinId
    trip.destinations ?= []
    destinations = trip.destinations
    Promise.map destinations, (destination) ->
      CheckIn.getById destination.id
      .then (checkIn) ->
        unless checkIn
          return
        PlacesService.getByTypeAndId checkIn.sourceType, checkIn.sourceId, {
          userId: trip.userId
        }
        .catch (err) -> null
        .then (place) ->
          checkIn.place = place
          checkIn
    .then (destinations) -> _.filter destinations, (destination) ->
      destination?.place?.location

  stopsInfo: (trip) ->
    # TODO: cache as a whole and maybe per checkinId
    trip.stops ?= {}
    stops = trip.stops
    Promise.props _.mapValues stops, (routeStops, routeId) ->
      Promise.map routeStops, (stop) ->
        CheckIn.getById stop.id
        .then (checkIn) ->
          unless checkIn
            return
          PlacesService.getByTypeAndId checkIn.sourceType, checkIn.sourceId, {
            userId: trip.userId
          }
          .catch (err) -> null
          .then (place) ->
            checkIn.place = place
            checkIn

  stats: ({checkIns}) ->
    stateCounts = _.countBy checkIns, ({place}) ->
      place?.address?.administrativeArea
    {stateCounts}

  overview: ({checkIns, route}) ->
    {
      stops: checkIns?.length
      distance: route?.distance
      time: route?.time
      startTime: _.minBy(checkIns, 'startTime')?.startTime
      endTime: _.maxBy(checkIns, 'endTime')?.endTime
    }

  route: ({checkIns}) ->
    # valhalla can do whole country, but a bunch of legs of whole country
    # (i think 3k miles?) will cause it to fail.
    # whole country takes 3-4 seconds

    # break it up into legs, use cache for legs we've already fetched...
    # only need to cache for maybe an hour
    locations = _.filter _.map checkIns, ({place}) ->
      place?.location
    # locations = _.clone(locations).reverse()
    pairs = RoutingService.pairwise locations

    minX = _.minBy locations, ({lon}) -> lon
    minY = _.minBy locations, ({lat}) -> lat
    maxX = _.maxBy locations, ({lon}) -> lon
    maxY = _.maxBy locations, ({lat}) -> lat
    if minX
      bounds = {
        x1: minX.lon - 1.5
        y1: maxY.lat + 1.5
        x2: maxX.lon + 1.5
        y2: minY.lat - 1.5
      }
    else
      {x1: -141.187, x2: 18.440, y1: -53.766, y2: 55.152}

    Promise.map pairs, (pair) ->
      RoutingService.getRoute {locations: pair}
    .then (routes) ->
      _.reduce routes, (combinedRoute, route) ->
        {
          legs: (combinedRoute.legs or []).concat route.legs
          time: (combinedRoute.time or 0) + (route.time or 0)
          distance: (combinedRoute.distance or 0) + (route.distance or 0)
          bounds: bounds
        }
      , {}

module.exports = new TripEmbed()
