_ = require 'lodash'
Joi = require 'joi'
Promise = require 'bluebird'
router = require 'exoid-router'
request = require 'request-promise'

PushToken = require '../models/push_token'
PushTopic = require '../models/push_topic'
User = require '../models/user'
PushNotificationService = require '../services/push_notification'
schemas = require '../schemas'
config = require '../config'

class PushTokensCtrl
  upsert: ({token, sourceType, language, deviceId}, {user, appKey}) =>
    userId = user.id

    Promise.all [
      User.updateById userId, {
        hasPushToken: true
      }
      # get any token obj associated with this token
      PushToken.getAllByToken token
      .then (pushTokens) =>
        # delete the token
        _.map pushTokens, PushToken.deleteByPushToken
        # delete any pushTopics
        _.map pushTokens, (pushToken) =>
          PushTopic.getAllByUserIdAndToken pushToken.userId, pushToken.token
          .map (pushTopic) =>
            Promise.all [
              PushTopic.deleteByPushTopic pushTopic
              PushNotificationService.unsubscribeToTopicByPushTopic pushTopic
            ]

        PushToken.upsert {
          token, deviceId, appKey
          userId: user.id
          sourceType: sourceType or pushTokens?[0]?.sourceType or 'android'
        }
      .then ->
        PushNotificationService.subscribeToAllUserTopics {
          userId
          token
          appKey
          deviceId
        }
    ]
    .then ->
      null


module.exports = new PushTokensCtrl()
