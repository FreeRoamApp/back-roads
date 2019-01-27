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

class TripCtrl
  upsert: (diff, {user}) ->
    diff = _.pick diff, ['checkInIds', 'id', 'imagePrefix', 'privacy']
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

  getAll: ({}, {user}) ->
    Trip.getAllByUserId user.id

  getById: ({id}, {user}) ->
    Trip.getById id
    .tap (trip) ->
      if trip?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'
    .then EmbedService.embed {embed: defaultEmbed}
    .then EmbedService.embed {embed: extrasEmbed}

  getByType: ({type}, {user}) ->
    Trip.getByUserIdAndType user.id, type, {createIfNotExists: true}
    .then EmbedService.embed {embed: defaultEmbed, options: {userId: user.id}}
    .then EmbedService.embed {embed: extrasEmbed}

  getByUserIdAndType: ({userId, type}, {user}) ->
    Trip.getByUserIdAndType userId, type
    .tap (trip) ->
      if trip?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'
    .then EmbedService.embed {embed: defaultEmbed, options: {userId}}
    # .then EmbedService.embed {embed: extrasEmbed}

  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'trips'}
    )

  getStatesGeoJson: ->
    statesGeoJson

module.exports = new TripCtrl()
