_ = require 'lodash'

BaseMessage = require './base_message'

class CommentEmbed
  user: (comment, {groupId}) ->
    if groupId and comment.userId
      BaseMessage.user {
        userId: comment.userId
        groupId: groupId
      }

  groupUser: (comment, {groupId}) ->
    if groupId and comment.userId
      comment.groupUser = BaseMessage.groupUser {
        userId: comment.userId, groupId: groupId
      }

  time: (comment) ->
    id = if typeof comment.id is 'string' \
               then cknex.getTimeUuidFromString comment.id
               else comment.id
    id.getDate()


module.exports = new CommentEmbed()
