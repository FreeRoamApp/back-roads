CronJob = require('cron').CronJob
_ = require 'lodash'
Promise = require 'bluebird'

CacheService = require './cache'
CleanupService = require './cleanup'
Thread = require '../models/thread'
Category = require '../models/category'
EarnAction = require '../models/earn_action'
Event = require '../models/event'
Group = require '../models/group'
Item = require '../models/item'
Amenity = require '../models/amenity'
Campground = require '../models/campground'
Product = require '../models/product'
AmazonService = require '../services/amazon'
FireService = require '../services/fire'
PlacesService = require '../services/places'
allCategories = require '../resources/data/categories'
# allGroups = require '../resources/data/groups'
allEvents = require '../resources/data/events'
allItems = require '../resources/data/items'
allAmenities = require '../resources/data/amenities'
allCampgrounds = require '../resources/data/campgrounds'
allEarnActions = require '../resources/data/earn_actions'
allProducts = require '../resources/data/products'
config = require '../config'
THIRTY_SECONDS = 30

class CronService
  constructor: ->
    @crons = []

    # minute
    @addCron 'quarterMinute', '15 * * * * *', ->
      console.log 'qmin'
      CleanupService.clean()
      Thread.updateScores 'stale'
      # if config.ENV is config.ENVS.DEV and config.SCYLLA.CONTACT_POINTS[0] is 'localhost' and config.ELASTICSEARCH.HOST is 'localhost'
      #   # Promise.map allGroups, (group) ->
      #   #   Group.upsert _.cloneDeep group
      #   Campground.batchUpsert _.cloneDeep allCampgrounds
      #   Event.batchUpsert _.cloneDeep allEvents
      #   Item.batchUpsert _.cloneDeep allItems
      #   Product.batchUpsert _.cloneDeep allProducts
      #   Amenity.batchUpsert _.cloneDeep allAmenities
      #   Category.batchUpsert _.cloneDeep allCategories

    @addCron 'tenMin', '0 */10 * * * *', ->
      EarnAction.batchUpsert _.cloneDeep allEarnActions
      Thread.updateScores 'time'

    @addCron 'oneHour', '0 22 * * * *', ->
      CleanupService.trimLeaderboards()
      # Promise.map allGroups, (group) ->
      #   Group.upsert _.cloneDeep group
      Item.batchUpsert _.cloneDeep allItems
      Amenity.batchUpsert _.cloneDeep allAmenities
      Event.batchUpsert _.cloneDeep allEvents
      # Campground.batchUpsert _.cloneDeep allCampgrounds
      Product.batchUpsert _.cloneDeep allProducts
      Category.batchUpsert _.cloneDeep allCategories

    @addCron 'daily', '0 0 3 * * *', -> # 3 am PT?
      if config.ENV is config.ENVS.PROD and not config.IS_STAGING
        FireService.dailyCron()
        .catch (err) ->
          console.log 'FIRE CRON FAIL', err
        .then ->
          PlacesService.updateAllDailyInfo()

  addCron: (key, time, fn) =>
    @crons.push new CronJob {
      cronTime: time
      onTick: ->
        CacheService.lock(key, fn, {
          # if server times get offset by >= 30 seconds, crons get run twice...
          # so this is not guaranteed to run just once
          expireSeconds: THIRTY_SECONDS
        })
      start: false
      timeZone: 'America/Los_Angeles'
    }

  start: =>
    _.map @crons, (cron) ->
      cron.start()

module.exports = new CronService()
