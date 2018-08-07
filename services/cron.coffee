CronJob = require('cron').CronJob
_ = require 'lodash'
Promise = require 'bluebird'

CacheService = require './cache'
CleanupService = require './cleanup'
# Thread = require '../models/thread'
Category = require '../models/category'
Item = require '../models/item'
Product = require '../models/product'
AmazonService = require '../services/amazon'
allCategories = require '../resources/data/categories'
allItems = require '../resources/data/items'
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
      # Thread.updateScores 'stale'
      # FIXME: running these every minute seems to cause memory leak?
      # Item.batchUpsert allItems
      # Product.batchUpsert allProducts
      # Category.batchUpsert allCategories

    @addCron 'tenMin', '0 */10 * * * *', ->
      # Thread.updateScores 'time'


    @addCron 'oneHour', '0 0 * * * *', ->
      CleanupService.trimLeaderboards()
      Category.batchUpsert allCategories
      Product.batchUpsert allProducts
      Item.batchUpsert allItems


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
