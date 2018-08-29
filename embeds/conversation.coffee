_ = require 'lodash'
Promise = require 'bluebird'

User = require '../models/user'
ConversationMessage = require '../models/conversation_message'

class ConversationEmbed
  users: (conversation) ->
    if conversation.userIds
      conversation.users = Promise.map conversation.userIds, (userId) ->
        User.getById userId, {preferCache: true}
      .map User.sanitizePublic null

  lastMessage: (conversation) ->
    ConversationMessage.getLastByConversationId conversation.id


module.exports = new ConversationEmbed()
