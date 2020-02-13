Promise = require 'bluebird'
_ = require 'lodash'

GiveawayEntry = require '../models/giveaway_entry'
TimeService = require '../services/time'
config = require '../config'

class GiveawayEntryCtrl
  getAll: ({}, {user}) ->
    timeBucket = TimeService.getScaledTimeByTimeScale 'week'
    console.log 'get', timeBucket, user.id
    GiveawayEntry.getAllByTimeBucketAndUserId timeBucket, user.id
    .then (entries) ->
      _.countBy entries, 'action'


module.exports = new GiveawayEntryCtrl()
