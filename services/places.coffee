Promise = require 'bluebird'
request = require 'request-promise'
_ = require 'lodash'

Amenity = require '../models/amenity'
AmenityAttachment = require '../models/amenity_attachment'
AmenityReview = require '../models/amenity_review'
Campground = require '../models/campground'
CampgroundAttachment = require '../models/campground_attachment'
CampgroundReview = require '../models/campground_review'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'
OvernightAttachment = require '../models/overnight_attachment'
OvernightReview = require '../models/overnight_review'
CacheService = require './cache'
WeatherService = require './weather'
JobCreateService = require './job_create'
RoutingService = require './routing'
config = require '../config'

ONE_MINUTE_SECONDS = 60
DAILY_UPDATE_PLACE_TIMEOUT = 30000
ONE_WEEK_S = 3600 * 24 * 7

PLACE_TYPES =
  campground: Campground
  overnight: Overnight
  amenity: Amenity

PLACE_ATTACHMENT_TYPES =
  campground: CampgroundAttachment
  overnight: OvernightAttachment
  amenity: AmenityAttachment

PLACE_REVIEW_TYPES =
  campground: CampgroundReview
  overnight: OvernightReview
  amenity: AmenityReview


DAILY_UPDATE_TYPES = ['campground', 'overnight']

class PlacesService
  getByTypeAndId: (type, id, {userId} = {}) ->
    unless id
      return Promise.resolve null
    if type is 'coordinate'
      Coordinate.getByUserIdAndId userId, id
    else
      Model = PLACE_TYPES[type] or Campground
      Model.getById id

  getAttachmentsByTypeAndId: (type, id) ->
    unless id
      return Promise.resolve []
    Model = PLACE_ATTACHMENT_TYPES[type] or CampgroundAttachment
    Model.getAllByParentId id

  getReviewsByTypeAndId: (type, id) ->
    unless id
      return Promise.resolve []
    Model = PLACE_REVIEW_TYPES[type] or CampgroundReview
    Model.getAllByParentId id

  upsertByTypeAndRow: (type, row, diff) ->
    PLACE_TYPES[type].upsertByRow row, diff

  deleteByTypeAndRow: (type, row) ->
    PLACE_TYPES[type].deleteByRow row

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

  setMapImage: (place) =>
    imagePrefix = "places/#{place.type}/#{place.id}_map"
    console.log "#{config.SCREENSHOTTER_HOST}/screenshot"
    Promise.resolve request "#{config.SCREENSHOTTER_HOST}/screenshot",
      json: true
      qs:
        imagePrefix: imagePrefix
        clipY: 32
        viewportHeight: 400
        width: 600
        height: 326
        # TODO: https
        url: "http://#{config.FREE_ROAM_HOST}/place-map-screenshot/#{place.type}/#{place.slug}"
    .then =>
      console.log imagePrefix
      @upsertByTypeAndRow place.type, {
        mapImagePrefix: imagePrefix
      }

  updateDailyInfo: ({id, type}) =>
    @getByTypeAndId type, id
    .then (place) =>
      console.log 'place', place.slug

      # @setMapImage place

      # RoutingService.getElevation {location: place.location}
      # .then (elevation) =>
      #   @upsertByTypeAndRow place.type, place, {elevation}

      Promise.all [
        WeatherService.getForecastDiff place
      ]
      .then ([forecastDiff]) =>
        @upsertByTypeAndRow place.type, place, forecastDiff


  updateAllDailyInfo: =>
    console.log 'update places'
    newDailyUpdateMinPlaceSlug = null
    CacheService.lock(
      CacheService.LOCKS.DAILY_UPDATE
      @_updateAllDailyInfoUncached
      {expireSeconds: 120, unlockWhenCompleted: true}
    )

  _updateAllDailyInfoUncached: =>
    console.log 'uncached'
    dailyUpdateIdCacheKey = CacheService.KEYS.DAILY_UPDATE_ID
    CacheService.get dailyUpdateIdCacheKey
    .then (dailyUpdateMinPlaceSlug) =>
      # dailyUpdateMinPlaceSlug = placeType:id
      dailyUpdateMinPlaceSlug ?= 'campground:0'
      [type, minPlaceSlug] = dailyUpdateMinPlaceSlug.split ':'
      console.log 'get by minId', type, minPlaceSlug
      PLACE_TYPES[type].getAllByMinSlug minPlaceSlug
      .then (places) =>
        if _.isEmpty places
          types = DAILY_UPDATE_TYPES
          currentTypeIndex = types.indexOf(type)
          if currentTypeIndex + 1 is types.length
            console.log 'end'
            return # just end it here, don't restart until next day
          else
            console.log 'bump'
            newType = types[(currentTypeIndex + 1) % types.length]
            newDailyUpdateMinPlaceSlug = "#{newType}:0"
        else
          newDailyUpdateMinPlaceSlug = "#{type}:#{_.last(places).slug}"
        console.log 'new', newDailyUpdateMinPlaceSlug
        console.log 'places', places.length
        # add each place to job
        # once all processed, call update again with new dailyUpdateMinPlaceSlug
        _.map places, ({slug, id}) ->
          JobCreateService.createJob {
            queueKey: 'DEFAULT'
            job: {id, type}
            type: JobCreateService.JOB_TYPES.DEFAULT.DAILY_UPDATE_PLACE
            ttlMs: DAILY_UPDATE_PLACE_TIMEOUT
            priority: JobCreateService.PRIORITIES.NORMAL
            waitForCompletion: true
          }
          .catch (err) ->
            console.log 'caught', id, err

        CacheService.set dailyUpdateIdCacheKey, newDailyUpdateMinPlaceSlug, {
          expireSeconds: ONE_MINUTE_SECONDS
        }
        .then =>
          unless _.isEmpty places
            @_updateAllDailyInfoUncached()

module.exports = new PlacesService()
