_ = require 'lodash'
Promise = require 'bluebird'

ConversationMessage = require '../models/conversation_message'
EmbedService = require '../services/embed'

defaultEmbed = [
  EmbedService.TYPES.CONVERSATION_MESSAGE.USER
  EmbedService.TYPES.CONVERSATION_MESSAGE.MENTIONED_USERS
  EmbedService.TYPES.CONVERSATION_MESSAGE.TIME
  EmbedService.TYPES.CONVERSATION_MESSAGE.GROUP_USER
]

class ConversationMessageService
  prepare: (conversationMessage) ->
    EmbedService.embed {
      embed: defaultEmbed
      # FIXME: pass groupId for groupUser embed. don't embed groupUser for pm
    }, ConversationMessage.defaultOutput(conversationMessage)
    .then (conversationMessage) ->
      # TODO: rm?
      if conversationMessage?.user?.flags?.isChatBanned isnt true
        conversationMessage


module.exports = new ConversationMessageService()
