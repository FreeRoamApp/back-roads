_ = require 'lodash'

GroupUserEmbed = require './group_user'
BaseMessage = require './base_message'
Comment = require '../models/comment'
CacheService = require '../services/cache'

FIVE_MINUTES_SECONDS = 60 * 5

class ThreadEmbed
  comments: (thread) ->
    key = CacheService.PREFIXES.COMMENTS_BY_TOP_ID + ':' + thread.id
    thread.comments = CacheService.preferCache key, ->
      Comment.getAllByTopId thread.id
      .map embedFn {embed: [TYPES.COMMENT.USER]}
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  commentCount: (thread) ->
    key = CacheService.PREFIXES.COMMENT_COUNT + ':' + thread.id
    thread.commentCount = CacheService.preferCache key, ->
      Comment.getCountByTopId thread.id
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
