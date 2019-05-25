_ = require 'lodash'

PlacesService = require '../services/places'

class CheckInEmbed
  place: (checkIn) ->
    PlacesService.getByTypeAndId checkIn.sourceType, checkIn.sourceId, {
      userId: checkIn.userId
    }

module.exports = new CheckInEmbed()
