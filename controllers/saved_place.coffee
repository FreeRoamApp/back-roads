Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

SavedPlace = require '../models/saved_place'
Amenity = require '../models/amenity'
Campground = require '../models/campground'
Overnight = require '../models/overnight'
CacheService = require '../services/cache'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24

class SavedPlaceCtrl
  defaultEmbed: []

  upsert: ({sourceId, sourceType}, {user}) =>
    SavedPlace.upsert {
      sourceId, sourceType
      userId: user.id
    }
    .tap ->
      category = "#{CacheService.PREFIXES.SAVED_PLACES_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category

  getAll: ({includeDetails}, {user}) =>
    includeDetails ?= false
    prefix = CacheService.PREFIXES.SAVED_PLACES_GET_ALL
    key = "#{prefix}:#{user.id}:#{includeDetails}"
    category = "#{CacheService.PREFIXES.SAVED_PLACES_GET_ALL}:#{user.id}"

    CacheService.preferCache key, ->
      SavedPlace.getAllByUserId user.id
      .map (savedPlace) ->
        if includeDetails
          (if savedPlace.sourceType is 'amenity'
            Amenity.getById savedPlace.sourceId
          else if savedPlace.sourceType is 'overnight'
            Overnight.getById savedPlace.sourceId
          else
            Campground.getById savedPlace.sourceId
          ).then (place) ->
            _.defaults savedPlace, place
        else
          savedPlace
    , {category, expireSeconds: ONE_DAY_SECONDS}


  deleteByRow: ({row}, {user}) =>
    SavedPlace.deleteByRow _.defaults({userId: user.id}, row)
    .tap ->
      category = "#{CacheService.PREFIXES.SAVED_PLACES_GET_ALL}:#{user.id}"
      CacheService.deleteByCategory category


module.exports = new SavedPlaceCtrl()
