_ = require 'lodash'

BaseMessage = require './base_message'

class BanEmbed
  user: (ban) ->
    if ban.userId
      BaseMessage.user {
        userId: ban.userId
      }

  bannedByUser: (ban) ->
    if ban.bannedById
      BaseMessage.user {
        userId: ban.bannedById
      }

module.exports = new BanEmbed()
