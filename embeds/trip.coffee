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

pairwise = (arr) ->
  newArr = []
  i = 0
  while i < arr.length - 1
    newArr.push [arr[i], arr[i + 1]]
    i += 1
  newArr

class TripEmbed
  user: (trip) ->
    if trip.userId
      BaseMessage.user {
        userId: trip.userId
      }

  checkIns: (trip) ->
    # TODO: cache as a whole and maybe per checkinId
    trip.checkInIds ?= []
    checkInIds = _.clone(trip.checkInIds).reverse()
    Promise.map checkInIds, (checkInId) ->
      CheckIn.getById checkInId
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
    .then (checkIns) -> _.filter checkIns

  stats: ({checkIns}) ->
    stateCounts = _.countBy checkIns, ({place}) ->
      place?.address?.administrativeArea
    {stateCounts}

  route: ({checkIns}) ->
    # valhalla can do whole country, but a bunch of legs of whole country
    # (i think 3k miles?) will cause it to fail.
    # whole country takes 3-4 seconds

    # break it up into legs, use cache for legs we've already fetched...
    # only need to cache for maybe an hour
    locations = _.filter _.map checkIns, ({place}) ->
      place?.location
    locations = _.clone(locations).reverse()
    pairs = pairwise locations

    Promise.map pairs, (pair) ->
      RoutingService.getRoute {locations: pair}
    .then (routes) ->
      _.reduce routes, (combinedRoute, route) ->
        {
          legs: (combinedRoute.legs or []).concat route.legs
          time: (combinedRoute.time or 0) + (route.time or 0)
          distance: (combinedRoute.distance or 0) + (route.distance or 0)
        }
      , {}

module.exports = new TripEmbed()
