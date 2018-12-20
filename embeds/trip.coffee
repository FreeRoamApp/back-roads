_ = require 'lodash'
Promise = require 'bluebird'

Amenity = require '../models/amenity'
Campground = require '../models/campground'
CheckIn = require '../models/check_in'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'

class CheckInEmbed
  checkIns: (trip, {userId}) ->
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
          Coordinate.getByUserIdAndId userId, checkIn.sourceId
        else
          Campground.getById checkIn.sourceId
        ).then (place) ->
          _.defaults checkIn, place

module.exports = new CheckInEmbed()
