_ = require 'lodash'

cknex = require '../services/cknex'
BaseMessage = require './base_message'
config = require '../config'

class AttachmentEmbed
  user: (attachment) ->
    if attachment.userId and "#{attachment.userId}" isnt config.EMPTY_UUID
      BaseMessage.user {
        userId: attachment.userId
      }

  time: (attachment) ->
    cknex.getDateFromTimeUuid attachment.id

module.exports = new AttachmentEmbed()
