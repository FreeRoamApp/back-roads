_ = require 'lodash'

BaseMessage = require './base_message'

class UserBlockEmbed
  user: (userBlock) ->
    if userBlock.blockedId
      BaseMessage.user {
        userId: userBlock.blockedId
      }

module.exports = new UserBlockEmbed()
