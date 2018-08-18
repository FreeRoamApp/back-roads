_ = require 'lodash'
Promise = require 'bluebird'

BaseMessage = require './base_message'

class ConversationMessageEmbed
  user: (conversationMessage) ->
    if conversationMessage.groupId and conversationMessage.userId
      BaseMessage.user {
        userId: conversationMessage.userId
        groupId: conversationMessage.groupId
      }

  groupUser: (conversationMessage) ->
    if conversationMessage.groupId and conversationMessage.userId
      conversationMessage.groupUser = BaseMessage.groupUser {
        userId: conversationMessage.userId, groupId: conversationMessage.groupId
      }

  time: (conversationMessage) ->
    id = if typeof conversationMessage.id is 'string' \
               then cknex.getTimeUuidFromString conversationMessage.id
               else conversationMessage.id
    id.getDate()

  mentionedUsers: (conversationMessage) ->
    text = conversationMessage.body
    mentions = _.map _.uniq(text?.match /\@[a-zA-Z0-9_-]+/g), (find) ->
      find.replace '@', ''
    mentions = _.take mentions, 5 # so people don't abuse
    Promise.map mentions, (username) ->
      BaseMessage.user {username, groupId: conversationMessage.groupId}

module.exports = new ConversationMessageEmbed()
