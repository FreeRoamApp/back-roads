_ = require 'lodash'

PlacesService = require '../services/places'
BaseMessage = require './base_message'

class UserLocationEmbed
  place: (userLocation) ->
    if userLocation.sourceId
      PlacesService.getByTypeAndId(
        userLocation.sourceType, userLocation.sourceId, {
          userId: userLocation.userId
        }
      )

  user: (userLocation) ->
    if userLocation.userId
      BaseMessage.user {
        userId: userLocation.userId
      }

module.exports = new UserLocationEmbed()
