_ = require 'lodash'

GroupUserEmbed = require './group_user'
BaseMessage = require './base_message'
ThreadComment = require '../models/thread_comment'
CacheService = require '../services/cache'

FIVE_MINUTES_SECONDS = 60 * 5

class ThreadEmbed
  comments: (thread) ->
    key = CacheService.PREFIXES.THREAD_COMMENTS + ':' + thread.id
    thread.comments = CacheService.preferCache key, ->
      ThreadComment.getAllByThreadId thread.id
      .map embedFn {embed: [TYPES.THREAD_COMMENT.USER]}
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  commentCount: (thread) ->
    key = CacheService.PREFIXES.THREAD_COMMENT_COUNT + ':' + thread.id
    thread.commentCount = CacheService.preferCache key, ->
      ThreadComment.getCountByThreadId thread.id
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  user: (thread, {groupId}) ->
    if thread.userId
      thread.user = BaseMessage.user {
        userId: thread.userId
        groupId: groupId
      }
    else
      thread.user = null


module.exports = new ThreadEmbed()
