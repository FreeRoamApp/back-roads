Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
statesGeoJson = require '../resources/data/states.json'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.TRIP.CHECK_INS
]
extrasEmbed = [
  EmbedService.TYPES.TRIP.ROUTE
  EmbedService.TYPES.TRIP.STATS
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
    .then EmbedService.embed {embed: extrasEmbed}

  getByType: ({type}, {user}) ->
    Trip.getByUserIdAndType user.id, type
    .then EmbedService.embed {embed: defaultEmbed, options: {userId: user.id}}
    .then EmbedService.embed {embed: extrasEmbed}
    .then (trip) ->
      if not trip and type in ['past', 'future']
        Trip.upsert {
          type
          userId: user.id
          name: _.startCase type
        }
      else
        trip

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

  getStatesGeoJson: ->
    statesGeoJson

module.exports = new TripCtrl()
