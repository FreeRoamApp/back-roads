_ = require 'lodash'

Amenity = require '../models/amenity'
Campground = require '../models/campground'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
CacheService = require './cache'

ONE_WEEK_S = 3600 * 24 * 7

class PlacesService
  getByTypeAndId: (type, id, {userId} = {}) ->
    unless id
      return Promise.resolve null
    (if type is 'amenity'
      Amenity.getById id
    else if type is 'overnight'
      Overnight.getById id
    else if type is 'coordinate'
      Coordinate.getByUserIdAndId userId, id
    else
      Campground.getById id
    )

  getByTypeAndSlug: (type, slug) ->
    unless slug
      return Promise.resolve null
    (if type is 'amenity'
      Amenity.getBySlug slug
    else if type is 'overnight'
      Overnight.getBySlug slug
    else
      Campground.getBySlug slug
    )

  getBestBounding: ({bbox, location, type, count}) ->
    count ?= 10
    type ?= 'campground'
    # TODO: other types
    prefix = CacheService.PREFIXES.PLACE_BEST_BOUNDING
    key = "#{prefix}:#{location.lat}:#{location.lon}:#{type}:#{count}"
    CacheService.preferCache key, ->
      Campground.searchNearby location, {distance: 3}
      .then ({places}) ->
        places = _.take places, 20
        places = places.concat [{location}]
        minX = _.minBy places, ({location}) -> location.lon
        minY = _.minBy places, ({location}) -> location.lat
        maxX = _.maxBy places, ({location}) -> location.lon
        maxY = _.maxBy places, ({location}) -> location.lat
        {
          x1: if bbox?[0] then Math.min(bbox[0], minX.location.lon) else minX.location.lon
          y1: if bbox?[3] then Math.max(bbox[3], maxY.location.lat) else maxY.location.lat
          x2: if bbox?[2] then Math.max(bbox[2], maxX.location.lon) else maxX.location.lon
          y2: if bbox?[1] then Math.min(bbox[1], minY.location.lat) else minY.location.lat
        }
    , {expireSeconds: ONE_WEEK_S}

module.exports = new PlacesService()
