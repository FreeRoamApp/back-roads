_ = require 'lodash'
Promise = require 'bluebird'

Amenity = require '../models/amenity'
Campground = require '../models/campground'
CheckIn = require '../models/check_in'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
RoutingService = require '../services/routing'

pairwise = (arr) ->
  newArr = []
  i = 0
  while i < arr.length - 1
    newArr.push [arr[i], arr[i + 1]]
    i += 1
  newArr

class CheckInEmbed
  checkIns: (trip) ->
    # TODO: cache as a whole and maybe per checkinId
    trip.checkInIds ?= []
    Promise.map trip.checkInIds, (checkInId) ->
      CheckIn.getById checkInId
      .then (checkIn) ->
        (if checkIn.sourceType is 'amenity'
          Amenity.getById checkIn.sourceId
        else if checkIn.sourceType is 'overnight'
          Overnight.getById checkIn.sourceId
        else if checkIn.sourceType is 'coordinate'
          Coordinate.getByUserIdAndId trip.userId, checkIn.sourceId
        else
          Campground.getById checkIn.sourceId
        ).then (place) ->
          _.defaults checkIn, place

  stats: ({checkIns}) ->
    stateCounts = _.countBy checkIns, ({address}) ->
      address?.administrativeArea
    {stateCounts}

  route: ({checkIns}) ->
    # valhalla can do whole country, but a bunch of legs of whole country
    # (i think 3k miles?) will cause it to fail.
    # whole country takes 3-4 seconds

    # break it up into legs, use cache for legs we've already fetched...
    # only need to cache for maybe an hour
    locations = _.map checkIns, 'location'
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

module.exports = new CheckInEmbed()
