_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

ThreadComment = require '../models/thread_comment'
ThreadVote = require '../models/thread_vote'
Thread = require '../models/thread'
GroupUser = require '../models/group_user'
Group = require '../models/group'
Ban = require '../models/ban'
CacheService = require '../services/cache'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.THREAD_COMMENT.USER
  EmbedService.TYPES.THREAD_COMMENT.GROUP_USER
  EmbedService.TYPES.THREAD_COMMENT.TIME
]

MAX_LENGTH = 10000
TEN_MINUTES_SECONDS = 60 * 10
MAX_COMMENT_DEPTH = 3

# there's probably a cleaner / more efficial way to this
getCommentsTree = (comments, findParentUuid, options) ->
  options ?= {}
  {depth, sort, skip, limit, getUnmatched} = options
  depth ?= 0
  limit ?= 50
  skip ?= 0

  if depth > MAX_COMMENT_DEPTH
    return {comments: [], unmatched: comments}

  {matchedComments, unmatched} = _.groupBy comments, ({parentUuid}) ->
    if "#{parentUuid}" is "#{findParentUuid}"
    then 'matchedComments'
    else 'unmatched'

  commentsTree = _.map matchedComments, (comment) ->
    # for each map step, reduce size of unmatched
    {comments, unmatched} = getCommentsTree(
      unmatched, comment.uuid, _.defaults {
        depth: depth + 1
        skip: 0
        getUnmatched: true
      }, options
    )
    comment.children = comments
    comment

  if sort is 'popular'
    comments = _.orderBy commentsTree, ({upvotes, downvotes}) ->
      upvotes - downvotes
    , 'desc'
  else
    comments = _.reverse commentsTree

  if getUnmatched
    {comments, unmatched}
  else
    comments

embedMyVotes = (comments, commentVotes) ->
  _.map comments, (comment) ->
    comment.myVote = _.find commentVotes, ({parentUuid}) ->
      "#{parentUuid}" is "#{comment.uuid}"
    comment.children = embedMyVotes comment.children, commentVotes
    comment

class ThreadCommentCtrl
  checkIfBanned: (groupUuid, ipAddr, userUuid, router) ->
    ipAddr ?= 'n/a'
    Promise.all [
      Ban.getByGroupUuidAndIp groupUuid, ipAddr, {preferCache: true}
      Ban.getByGroupUuidAndUserUuid groupUuid, userUuid, {preferCache: true}
    ]
    .then ([bannedIp, bannedUserUuid]) ->
      if bannedIp?.ip or bannedUserUuid?.userUuid
        router.throw status: 403, 'unable to post'

  create: ({body, threadUuid, parentUuid, parentType}, {user, headers, connection}) =>
    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    body = body.trim()

    msPlayed = Date.now() - user.joinTime?.getTime()

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post...'

    if body?.length > MAX_LENGTH and not user?.flags?.isModerator
      router.throw status: 400, info: 'message is too long...'

    unless body
      router.throw status: 400, info: 'can\'t be empty'

    Thread.getByUuid threadUuid, {preferCache: true, omitCounter: true}
    .then (thread) =>
      @checkIfBanned thread.groupUuid, ip, user.uuid, router
      .then ->
        ThreadComment.upsert
          userUuid: user.uuid
          body: body
          threadUuid: threadUuid
          parentUuid: parentUuid
          parentType: parentType
      .then ->
        prefix = CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID_CATEGORY
        Promise.all [
          CacheService.deleteByCategory "#{prefix}:#{threadUuid}"
        ]

  getAllByThreadUuid: ({threadUuid, sort, skip, limit, groupUuid}, {user}) ->
    sort ?= 'popular'
    skip ?= 0
    prefix = CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID
    categoryPrefix = CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID_CATEGORY
    key = "#{prefix}:#{threadUuid}:#{sort}:#{skip}:#{limit}"
    category = "#{categoryPrefix}:#{threadUuid}"
    CacheService.preferCache key, ->
      ThreadComment.getAllByThreadUuid threadUuid
      .map EmbedService.embed {embed: defaultEmbed, options: {groupUuid}}
      .then (allComments) ->
        getCommentsTree allComments, threadUuid, {sort, skip, limit}
    , {category, expireSeconds: TEN_MINUTES_SECONDS}
    .then (comments) ->
      comments = comments?.slice skip, skip + limit
      ThreadVote.getAllByUserUuidAndParentTopUuid user.uuid, threadUuid
      .then (commentVotes) ->
        embedMyVotes comments, commentVotes

  flag: ({uuid}, {headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    # TODO
    ThreadComment.getByUuid uuid
    .then EmbedService.embed {
      embed: [EmbedService.TYPES.THREAD_COMMENT.USER]
    }

  deleteByThreadComment: ({threadComment, groupUuid}, {user}) ->
    permission = GroupUser.PERMISSIONS.DELETE_FORUM_COMMENT
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [permission]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      ThreadComment.deleteByThreadComment threadComment
      .tap ->
        prefix = CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID_CATEGORY
        CacheService.deleteByCategory "#{prefix}:#{threadComment.threadUuid}"

  deleteAllByGroupUuidAndUserUuid: ({groupUuid, userUuid, threadUuid}, {user}) ->
    permission = GroupUser.PERMISSIONS.DELETE_FORUM_COMMENT
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [permission]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      ThreadComment.deleteAllByUserUuid userUuid
      .tap ->
        if threadUuid
          prefix = CacheService.PREFIXES.THREAD_COMMENTS_THREAD_ID_CATEGORY
          CacheService.deleteByCategory "#{prefix}:#{threadUuid}"

module.exports = new ThreadCommentCtrl()
