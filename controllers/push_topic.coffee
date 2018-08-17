_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

PushTopic = require '../models/push_topic'
PushNotificationService = require '../services/push_notification'
config = require '../config'

class PushTopicCtrl
  subscribe: ({groupUuid, appKey, sourceType, sourceId}, {user}) ->
    PushNotificationService.subscribeToTopic {
      groupUuid, appKey, sourceType, sourceId
      userUuid: user.uuid
    }

module.exports = new PushTopicCtrl()
