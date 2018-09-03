CronJob = require('cron').CronJob
_ = require 'lodash'
Promise = require 'bluebird'

CacheService = require './cache'
CleanupService = require './cleanup'
Thread = require '../models/thread'
Category = require '../models/category'
Group = require '../models/group'
Item = require '../models/item'
Place = require '../models/place'
Product = require '../models/product'
AmazonService = require '../services/amazon'
allCategories = require '../resources/data/categories'
allGroups = require '../resources/data/groups'
allItems = require '../resources/data/items'
allPlaces = require '../resources/data/places'
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
      # FIXME: running these every minute seems to cause memory leak?
      if config.ENV is config.ENVS.DEV
        Promise.map allGroups, (group) ->
          Group.upsert _.cloneDeep group
        Item.batchUpsert _.cloneDeep allItems
        Place.batchUpsert _.cloneDeep allPlaces
        Product.batchUpsert _.cloneDeep allProducts
        Category.batchUpsert _.cloneDeep allCategories

    @addCron 'tenMin', '0 */10 * * * *', ->
      Thread.updateScores 'time'


    @addCron 'oneHour', '0 20 * * * *', ->
      CleanupService.trimLeaderboards()
      Category.batchUpsert _.cloneDeep allCategories
      Product.batchUpsert _.cloneDeep allProducts
      Item.batchUpsert _.cloneDeep allItems


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
