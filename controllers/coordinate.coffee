Promise = require 'bluebird'
_ = require 'lodash'

Coordinate = require '../models/coordinate'
EmbedService = require '../services/embed'
GeocoderService = require '../services/geocoder'
PlaceBaseCtrl = require './place_base'
config = require '../config'

class CoordinateCtrl extends PlaceBaseCtrl
  type: 'coordinate'
  Model: Coordinate
  defaultEmbed: []

  search: ({}, {user}) ->
    # TODO: when implementing this, be sure to make sure a filter for userId
    # is present and the same as user.id (so people can't see others' coords)
    return false
    super

  upsert: ({userId, location, name}, {user}) ->
    slug = _.kebabCase name

    unless location.lon and location.lat
      matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec location
      unless matches?[0] and matches?[1]
        console.log 'invalid', location
        router.throw {info: 'invalid location', status: 400}
      location = {
        lat: parseFloat(matches[1])
        lon: parseFloat(matches[2])
      }

    GeocoderService.reverse location
    .then (address) ->
      Coordinate.getByUserIdAndSlug user.id, slug
      .then (coordinate) ->
        id = coordinate?.id
        Coordinate.upsert {userId: user.id, location, address, name, slug, id}


module.exports = new CoordinateCtrl()
