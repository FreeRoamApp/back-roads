CronJob = require('cron').CronJob
_ = require 'lodash'
Promise = require 'bluebird'

CacheService = require './cache'
VideoDiscoveryService = require './video_discovery'
EventService = require './event'
CleanupService = require './cleanup'
ClashRoyaleService = require './game_clash_royale'
FortniteService = require './game_fortnite'
Thread = require '../models/thread'
Item = require '../models/item'
Product = require '../models/product'
Iap = require '../models/iap'
EarnAction = require '../models/earn_action'
SpecialOffer = require '../models/special_offer'
ClashRoyaleDeck = require '../models/clash_royale_deck'
ClashRoyaleCard = require '../models/clash_royale_card'
ClashRoyalePlayerDeck = require '../models/clash_royale_player_deck'
GroupUser = require '../models/group_user'
Ban = require '../models/ban'
NewsRoyaleService = require '../services/news_royale'
allItems = require '../resources/data/items'
allProducts = require '../resources/data/products'
allIap = require '../resources/data/iap'
allEarnActions = require '../resources/data/earn_actions'
allSpecialOffers = require '../resources/data/special_offers'
r = require './rethinkdb'
config = require '../config'

THIRTY_SECONDS = 30

class CronService
  constructor: ->
    @crons = []

    # minute
    @addCron 'minute', '0 * * * * *', ->
      EventService.notifyForStart()
      if config.ENV is config.ENVS.PROD and not config.IS_STAGING
        CacheService.get CacheService.KEYS.AUTO_REFRESH_SUCCESS_COUNT
        .then (successCount) ->
          unless successCount
            console.log 'starting auto refresh'
            ClashRoyaleService.updateAutoRefreshPlayers()

    @addCron 'quarterMinute', '15 * * * * *', ->
      CleanupService.clean()
      Thread.updateScores 'stale'

    @addCron 'fiveMinute', '30 */5 * * * *', ->
      if config.ENV is config.ENVS.PROD
        ClashRoyaleService.updateTopPlayers()

    @addCron 'tenMin', '0 */10 * * * *', ->
      Iap.batchUpsert allIap
      Product.batchUpsert allProducts
      Item.batchUpsert allItems
      SpecialOffer.batchUpsert allSpecialOffers
      EarnAction.batchUpsert allEarnActions
      Thread.updateScores 'time'
      VideoDiscoveryService.updateGroupVideos config.GROUPS.PLAY_HARD.ID
      VideoDiscoveryService.updateGroupVideos config.GROUPS.NICKATNYTE.ID
      # VideoDiscoveryService.updateGroupVideos config.GROUPS.NINJA.ID
      VideoDiscoveryService.updateGroupVideos config.GROUPS.THE_VIEWAGE.ID
      # VideoDiscoveryService.updateGroupVideos config.GROUPS.FERG.ID
      if config.ENV is config.ENVS.PROD and not config.IS_STAGING
        NewsRoyaleService.scrape()
        FortniteService.syncNews()

    @addCron 'oneHour', '0 0 * * * *', ->
      CleanupService.trimLeaderboards()


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
