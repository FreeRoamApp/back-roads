_ = require 'lodash'
Joi = require 'joi'
Promise = require 'bluebird'
router = require 'exoid-router'

PushToken = require '../models/push_token'
Subscription = require '../models/subscription'
User = require '../models/user'
config = require '../config'

# pushToken flow is documented in controllers/subscription

class PushTokensCtrl
  # store a new pushToken and re-create all subscribed topics for that token
  upsert: ({token, sourceType, deviceId}, {user}) =>
    userId = user.id

    # delete existing push tokens (tokens for other userIds). important since
    # this is called after logging in
    PushToken.getAllByToken token
    .then (pushTokens) ->
      # check if token already exists...
      if _.find pushTokens, {
        userId: user.id, token, sourceType, deviceId, errorCount: 0
      }
        return # don't need to do anything...

      # delete the token
      Promise.all _.filter [
        Promise.map pushTokens, PushToken.deleteByPushToken
        # delete any subscriptions
        Promise.map pushTokens, (pushToken) ->
          unless token is 'none'
            Subscription.getAllByToken pushToken.token
            .map Subscription.unsubscribeBySubscriptionToken
        .catch (err) ->
          console.log 'push token subscribe error', err
      ]
      .then ->
        PushToken.upsert {
          token, deviceId
          userId: user.id
          sourceType: pushTokens?[0]?.sourceType or sourceType or 'android'
        }
      .then ->
        Subscription.subscribeNewTokenByUserId userId, {token, deviceId}
    .then ->
      null


module.exports = new PushTokensCtrl()
