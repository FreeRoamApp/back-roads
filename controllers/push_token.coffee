_ = require 'lodash'
Joi = require 'joi'
Promise = require 'bluebird'
router = require 'exoid-router'

PushToken = require '../models/push_token'
Subscription = require '../models/subscription'
User = require '../models/user'
config = require '../config'

class PushTokensCtrl
  # store a new pushToken and re-create all subscribed topics for that token
  upsert: ({token, sourceType, language, deviceId}, {user}) =>
    userId = user.id

    # delete existing push tokens (tokens for other userIds). important since
    # this is called after logging in
    console.log 'upsert', user.id
    PushToken.getAllByToken token
    .then (pushTokens) ->
      # delete the token
      Promise.all _.filter [
        Promise.map pushTokens, PushToken.deleteByPushToken
        # delete any subscriptions
        Promise.map pushTokens, (pushToken) ->
          unless token is 'none'
            Subscription.getAllByToken pushToken.token
            .map Subscription.unsubscribeBySubscriptionToken
      ]
    .then ->
      PushToken.upsert {
        token, deviceId
        userId: user.id
        sourceType: sourceType or pushTokens?[0]?.sourceType or 'android'
      }
    .then ->
      Subscription.subscribeNewTokenByUserId userId, {token, deviceId}
    .then ->
      null


module.exports = new PushTokensCtrl()
