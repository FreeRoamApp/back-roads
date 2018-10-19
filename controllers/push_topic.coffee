_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

PushTopic = require '../models/push_topic'
PushNotificationService = require '../services/push_notification'
config = require '../config'

class PushTopicCtrl
  # TODO: use user.groupUserSettings.globalNotifications instead of manually getting topics
  getAll: ({}, {user}) ->
    PushTopic.getAllByUserId user.id

  subscribe: ({groupId, sourceType, sourceId}, {user}) ->
    PushNotificationService.subscribeToPushTopic {
      groupId, sourceType, sourceId
      userId: user.id
    }

  unsubscribe: ({groupId, sourceType, sourceId}, {user}) ->
    PushNotificationService.unsubscribeToPushTopic {
      groupId, sourceType, sourceId
      userId: user.id
    }


module.exports = new PushTopicCtrl()
