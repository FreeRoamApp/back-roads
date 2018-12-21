Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
RoutingService = require '../services/routing'
config = require '../config'

pairwise = (arr) ->
  newArr = []
  i = 0
  while i < arr.length - 1
    newArr.push [arr[i], arr[i + 1]]
    i += 1
  newArr

defaultEmbed = [
  EmbedService.TYPES.TRIP.CHECK_INS
]

# TODO: Trip.hasPermission (add as base model method)
# TODO: Base controller component w/ upsert?

class TripCtrl
  upsert: (diff, {user}) ->
    diff = _.pick diff, ['checkInIds', 'id', 'imagePrefix']
    diff = _.defaults {userId: user.id}, diff
    (if diff.id
      Trip.getById diff.id
    else
      Promise.resolve null
    )
    .then (trip) ->
      if trip and "#{trip.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}
      Trip.upsertByRow trip, diff

  getById: ({id}, {user}) ->
    Trip.getById id
    .then EmbedService.embed {embed: defaultEmbed, options: {userId: user.id}}

  getByType: ({type}, {user}) ->
    Trip.getByUserIdAndType user.id, type
    .then EmbedService.embed {embed: defaultEmbed, options: {userId: user.id}}
    .then (trip) ->
      if not trip and type in ['past', 'future']
        Trip.upsert {
          type
          userId: user.id
          name: _.startCase type
        }
      else
        trip

  getRoute: ({checkIns}, {user}) ->
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

  addCheckIn: ({id, name, sourceId, sourceType}, {user}) ->
    Trip.getById id
    .then (trip) ->
      unless "#{trip.userId}" is "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}
      CheckIn.upsert {
        name, sourceId, sourceType
        userId: user.id
        tripIds: [id]
        status: 'visited'
      }
      .then (checkIn) ->
        Trip.upsertByRow trip, {}, {add: {checkInIds: [[checkIn.id]]}}

  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'trips'}
    )

module.exports = new TripCtrl()
