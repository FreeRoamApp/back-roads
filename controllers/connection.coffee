_ = require 'lodash'
Promise = require 'bluebird'
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
  getAllGrouped: ({userId}, {user}) ->
    userId ?= user.id
    Connection.getAllByUserId userId
    .then (connections) ->
      groupedConnections = _.groupBy connections, 'type'
      _.mapValues groupedConnections, (connections) ->
        _.map connections, 'otherId'

  getAllIdsByType: ({userId, type}, {user}) ->
    userId ?= user.id
    Connection.getAllByUserIdAndType userId, type
    .map (connection) ->
      connection.otherId

  getAllByType: ({type}, {user}) ->
    Connection.getAllByUserIdAndType user.id, type
    .map EmbedService.embed {embed: otherEmbed}

  getAllByUserIdAndType: ({userId, type, embed}, {user}) ->
    userId ?= user.id
    Connection.getAllByUserIdAndType userId, type
    .map EmbedService.embed {embed: otherEmbed}

  acceptRequestByUserIdAndType: ({userId, type}, {user}) ->
    otherId = userId
    # make sure there's a request
    Connection.getByUserIdAndOtherIdAndType(
      user.id, otherId, "#{type}RequestReceived"
    )
    .then (request) ->
      if request
        Connection.upsert {userId: user.id, otherId, type}
        .then ->
          Connection.deleteByUserIdAndOtherIdAndType(
            user.id, otherId, "#{type}RequestReceived"
          )
        .tap ->
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
                  key: 'social'
            }

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
              key: 'social'
        }
      .catch -> null
      null

  deleteByUserIdAndType: ({userId, type}, {user}) ->
    otherId = userId
    Connection.deleteByUserIdAndOtherIdAndType user.id, otherId, type


module.exports = new ConnectionCtrl()
