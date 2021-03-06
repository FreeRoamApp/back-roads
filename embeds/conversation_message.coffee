_ = require 'lodash'
Promise = require 'bluebird'

config = require '../config'
BaseMessage = require './base_message'
cknex = require '../services/cknex'

class ConversationMessageEmbed
  user: (conversationMessage) ->
    if conversationMessage.userId
      BaseMessage.user {
        userId: conversationMessage.userId
        groupId: conversationMessage.groupId or config.EMPTY_UUID
      }

  groupUser: (conversationMessage) ->
    if conversationMessage.groupId and conversationMessage.userId
      conversationMessage.groupUser = BaseMessage.groupUser {
        userId: conversationMessage.userId, groupId: conversationMessage.groupId
      }

  time: (conversationMessage) ->
    cknex.getDateFromTimeUuid conversationMessage.id

  mentionedUsers: (conversationMessage) ->
    text = conversationMessage.body
    mentions = _.map _.uniq(text?.match /\@[a-zA-Z0-9_-]+/g), (find) ->
      find.replace('@', '').toLowerCase()
    mentions = _.take mentions, 5 # so people don't abuse
    Promise.map mentions, (username) ->
      BaseMessage.user {username, groupId: conversationMessage.groupId}

module.exports = new ConversationMessageEmbed()
