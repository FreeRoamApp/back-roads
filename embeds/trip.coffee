_ = require 'lodash'
Promise = require 'bluebird'

Amenity = require '../models/amenity'
BaseMessage = require './base_message'
Campground = require '../models/campground'
CheckIn = require '../models/check_in'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
Trip = require '../models/trip'
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
    .then (destinations) ->
      _.filter destinations, (destination) ->
        destination?.place?.location

  stopsInfo: (trip) ->
    # TODO: cache as a whole and maybe per checkinId
    trip.stops ?= {}
    stops = trip.stops
    Promise.props _.mapValues stops, (routeStops, routeId) ->
      Promise.map routeStops, (stop) ->
        if stop.isWaypoint
          return
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


  overview: ({destinationsInfo, destinations}) ->
    stateCounts = _.countBy destinationsInfo, ({place}) ->
      place?.address?.administrativeArea
    {
      stateCounts: stateCounts
      stops: destinationsInfo?.length or destinations?.length or 0
      distance: route?.distance
      time: route?.time
      startTime: _.minBy(destinationsInfo, 'startTime')?.startTime
      endTime: _.maxBy(destinationsInfo, 'endTime')?.endTime
    }

  routes: ({id}) ->
    Trip.getAllRoutesByTripId id

module.exports = new TripEmbed()
