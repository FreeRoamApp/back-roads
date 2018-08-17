_ = require 'lodash'

GroupUserEmbed = require './group_user'
BaseMessage = require './base_message'
ThreadComment = require '../models/thread_comment'
CacheService = require '../services/cache'

FIVE_MINUTES_SECONDS = 60 * 5

class ThreadEmbed
  comments: (thread) ->
    key = CacheService.PREFIXES.THREAD_COMMENTS + ':' + thread.uuid
    thread.comments = CacheService.preferCache key, ->
      ThreadComment.getAllByThreadUuid thread.uuid
      .map embedFn {embed: [TYPES.THREAD_COMMENT.USER]}
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  commentCount: (thread) ->
    key = CacheService.PREFIXES.THREAD_COMMENT_COUNT + ':' + thread.uuid
    thread.commentCount = CacheService.preferCache key, ->
      ThreadComment.getCountByThreadUuid thread.uuid
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  user: (thread, {groupUuid}) ->
    if thread.userUuid
      thread.user = BaseMessage.user {
        userUuid: thread.userUuid
        groupUuid: groupUuid
      }
    else
      thread.user = null


module.exports = new ThreadEmbed()
