_ = require 'lodash'

BaseMessage = require './base_message'

class AttachmentEmbed
  user: (attachment) ->
    if attachment.userId
      BaseMessage.user {
        userId: attachment.userId
      }

  time: (attachment) ->
    id = if typeof attachment.id is 'string' \
               then cknex.getTimeUuidFromString attachment.id
               else attachment.id
    id.getDate()

module.exports = new AttachmentEmbed()
