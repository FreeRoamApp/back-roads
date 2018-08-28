_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

PushTopic = require '../models/push_topic'
PushNotificationService = require '../services/push_notification'
config = require '../config'

class PushTopicCtrl
  subscribe: ({groupId, sourceType, sourceId}, {user}) ->
    PushNotificationService.subscribeToTopic {
      groupId, sourceType, sourceId
      userId: user.id
    }

module.exports = new PushTopicCtrl()
