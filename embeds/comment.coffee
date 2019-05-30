_ = require 'lodash'

cknex = require '../services/cknex'
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
    cknex.getDateFromTimeUuid comment.id


module.exports = new CommentEmbed()
