_ = require 'lodash'

BaseMessage = require './base_message'
config = require '../config'

class AttachmentEmbed
  user: (attachment) ->
    if attachment.userId and "#{attachment.userId}" isnt config.EMPTY_UUID
      BaseMessage.user {
        userId: attachment.userId
      }

  time: (attachment) ->
    id = if typeof attachment.id is 'string' \
               then cknex.getTimeUuidFromString attachment.id
               else attachment.id
    id.getDate()

module.exports = new AttachmentEmbed()
