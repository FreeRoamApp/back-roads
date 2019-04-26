_ = require 'lodash'

BaseMessage = require './base_message'

class ConnectionEmbed
  user: (connection) ->
    if connection.userId
      BaseMessage.user {
        userId: connection.userId
      }

  other: (connection) ->
    if connection.otherId
      BaseMessage.other {
        otherId: connection.otherId
      }

module.exports = new ConnectionEmbed()
