_ = require 'lodash'

BaseMessage = require './base_message'

class ReviewEmbed
  user: (review) ->
    if review.userId
      BaseMessage.user {
        userId: review.userId
      }

  time: (review) ->
    id = if typeof review.id is 'string' \
               then cknex.getTimeUuidFromString review.id
               else review.id
    id.getDate()

module.exports = new ReviewEmbed()
