_ = require 'lodash'
Promise = require 'bluebird'

User = require '../models/user'
Language = require '../models/language'
CacheService = require './cache'
KueCreateService = require './kue_create'
PushNotificationService = require './push_notification'
config = require '../config'

AMOUNT_PER_BATCH = 500
AMOUNT_PER_GET = 20000
TIME_PER_BATCH_SECONDS = 5
FIVE_MINUTE_SECONDS = 5 * 60

class BroadcastService
  failSafe: ->
    CacheService.set CacheService.KEYS.BROADCAST_FAILSAFE, true, {
      expireSeconds: FIVE_MINUTE_SECONDS
    }

  start: (message, {isTestRun}) =>
    console.log 'broadcast start', message.title
    @batch message, {isTestRun}

  batch: (message, {isTestRun, minId}) =>
    console.log 'minId', minId
    minId ?= '0000'
    (if isTestRun
      r.table 'users'
      .getAll 'austin', {index: 'username'}
      .pluck ['uuid', 'country', 'language']
    else
      r.table('users')
      .between([true, minId], [true, 'ZZZZ'], {index: 'pushToken'})
      .orderBy {index: r.asc 'pushToken'}
      .limit AMOUNT_PER_GET
      .pluck(['uuid', 'country', 'language'])
    )
    .then (users) =>
      if message.filterLang and not isTestRun
        console.log 'filtering', message.filterLang, users.length
        users = _.filter users, ({language, country}) =>
          language or= @getLangCode(country)
          language is message.filterLang

      userUuids = _.map users, 'uuid'
      console.log 'sending to ', userUuids.length

      userGroups = _.values _.chunk(userUuids, AMOUNT_PER_BATCH)

      delay = 0
      _.map userGroups, (groupUserUuids, i) ->
        KueCreateService.createJob
          job: {
            userUuids: groupUserUuids
            message: message
            percentage: i / userGroups.length
          }
          delaySeconds: delay
          type: KueCreateService.JOB_TYPES.BATCH_NOTIFICATION
        delay += TIME_PER_BATCH_SECONDS
      console.log 'batch done'
      if userUuids.length >= AMOUNT_PER_GET
        @batch message, {isTestRun, minId: _.last userUuids}

  batchNotify: ({userUuids, message, percentage}) ->
    console.log 'batch', userUuids.length, percentage
    CacheService.get CacheService.KEYS.BROADCAST_FAILSAFE
    .then (failSafe) ->
      if failSafe
        console.log 'skipping (failsafe)'
      else
        Promise.map userUuids, (userUuid) ->
          User.getByUuid userUuid
          .then (user) ->
            langCode = Language.getLanguageByCountry user.country
            lang = message.lang[langCode] or message.lang['en']
            message = _.defaults {
              title: lang.title
              text: lang.text
            }, _.clone(message)
            PushNotificationService.send user, message
            .catch (err) ->
              console.log 'push error', err
        .catch (err) ->
          console.log err
          console.log 'map error'

  broadcast: (message, {isTestRun, uniqueId}) =>
    key = "#{CacheService.LOCK_PREFIXES.BROADCAST}:#{uniqueId}"
    console.log 'broadcast.broadcast', key
    if message.allowRebroadcast
      @start message, {isTestRun}
    else
      CacheService.lock key, =>
        @start message, {isTestRun}

module.exports = new BroadcastService()
