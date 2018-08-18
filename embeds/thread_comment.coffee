_ = require 'lodash'

BaseMessage = require './base_message'

class ThreadCommentEmbed
  user: (threadComment, {groupId}) ->
    if groupId and threadComment.userId
      BaseMessage.user {
        userId: threadComment.userId
        groupId: groupId
      }

  groupUser: (threadComment, {groupId}) ->
    if groupId and threadComment.userId
      threadComment.groupUser = BaseMessage.groupUser {
        userId: threadComment.userId, groupId: groupId
      }

  time: (threadComment) ->
    id = if typeof threadComment.id is 'string' \
               then cknex.getTimeUuidFromString threadComment.id
               else threadComment.id
    id.getDate()


module.exports = new ThreadCommentEmbed()
