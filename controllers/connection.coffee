_ = require 'lodash'
router = require 'exoid-router'

Subscription = require '../models/subscription'
Connection = require '../models/connection'
User = require '../models/user'
EmbedService = require '../services/embed'
PushNotificationService = require '../services/push_notification'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.CONNECTION.USER]
otherEmbed = [EmbedService.TYPES.CONNECTION.OTHER]

class ConnectionCtrl
  getAllIdsByType: ({userId, type}, {user}) ->
    userId ?= user.id
    Connection.getAllByUserIdAndType userId, type
    .map (connection) ->
      connection.otherId

  getAllByType: ({type}, {user}) ->
    Connection.getAllByUserIdAndType user.id, type

  getAllByUserIdAndType: ({userId, type, embed}, {user}) ->
    userId ?= user.id
    Connection.getAllByUserIdAndType userId, type
    .map EmbedService.embed {embed: otherEmbed}

  upsertByUserIdAndType: ({userId, type}, {user}) ->
    otherId = userId
    Connection.getByUserIdAndOtherIdAndType user.id, otherId, type
    .then (connection) ->
      unless connection
        Connection.upsert {userId: user.id, otherId: otherId, type}
    .then ->
      User.getById otherId
      .then (otherUser) ->
        PushNotificationService.send otherUser, {
          titleObj:
            key: "newConnection.#{type}Title"
          type: Subscription.TYPES.SOCIAL
          textObj:
            key: "newConnection.#{type}Text"
            replacements:
              name: User.getDisplayName(user)
          data:
            path:
              key: 'people'
        }
      .catch -> null
      null

  deleteByUserIdAndType: ({userId, type}, {user}) ->
    otherId = userId
    Connection.deleteByUserIdAndOtherIdAndType user.id, otherId, type


module.exports = new ConnectionCtrl()
