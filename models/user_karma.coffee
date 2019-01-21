_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

class UserKarma extends Base
  SCYLLA_TABLES: [
    {
      name: 'user_karma_counter_by_userId'
      keyspace: 'free_roam'
      ignoreUpsert: true
      fields:
        userId: 'uuid'
        karma: 'counter'
      primaryKey:
        partitionKey: ['userId']
    }
  ]

  getByUserId: (userId) =>
    cknex().select '*'
    .from 'user_karma_counter_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}
    .then ({karma} = {}) ->
      if karma then parseInt(karma) else 0

  incrementByUserId: (userId, amount) ->
    updateKarma = cknex().update 'user_karma_counter_by_userId'
    .increment 'karma', amount
    .andWhere 'userId', '=', userId
    .run()

    Promise.all [
      updateKarma

      key = CacheService.STATIC.KARMA_LEADERBOARD
      CacheService.leaderboardIncrement key, userId, amount, {
        currentValueFn: =>
          updateKarma.then =>
            @getByUserId userId
      }
    ]

  getTop: ->
    key = CacheService.STATIC.KARMA_LEADERBOARD
    CacheService.leaderboardGet key
    .then (results) ->
      _.map _.chunk(results, 2), ([userId, karma], i) ->
        {
          rank: i + 1
          userId
          karma: parseInt karma
        }

module.exports = new UserKarma()
