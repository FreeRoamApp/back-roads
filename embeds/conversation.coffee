_ = require 'lodash'
Promise = require 'bluebird'

User = require '../models/user'

class ConversationEmbed
  users: (conversation) ->
    if conversation.userIds
      conversation.users = Promise.map conversation.userIds, (userId) ->
        User.getById userId, {preferCache: true}
      .map User.sanitizePublic null


module.exports = new ConversationEmbed()
