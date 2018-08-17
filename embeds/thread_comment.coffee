_ = require 'lodash'

BaseMessage = require './base_message'

class ThreadCommentEmbed
  user: (threadComment, {groupUuid}) ->
    if groupUuid and threadComment.userUuid
      BaseMessage.user {
        userUuid: threadComment.userUuid
        groupUuid: groupUuid
      }

  groupUser: (threadComment, {groupUuid}) ->
    if groupUuid and threadComment.userUuid
      threadComment.groupUser = BaseMessage.groupUser {
        userUuid: threadComment.userUuid, groupUuid: groupUuid
      }

  time: (threadComment) ->
    uuid = if typeof threadComment.uuid is 'string' \
               then cknex.getTimeUuidFromString threadComment.uuid
               else threadComment.uuid
    threadComment.time = uuid.getDate()


module.exports = new ThreadCommentEmbed()
