_ = require 'lodash'

BaseMessage = require './base_message'
Trip = require '../models/trip'

class TripFollowerEmbed
  user: (tripFollower) ->
    if tripFollower.blockedId
      BaseMessage.user {
        userId: tripFollower.blockedId
      }

  trip: (tripFollower) ->
    Trip.getById tripFollower.tripId

module.exports = new TripFollowerEmbed()
