_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

Comment = require '../models/comment'
Vote = require '../models/vote'
GroupUser = require '../models/group_user'
Group = require '../models/group'
Ban = require '../models/ban'
Subscription = require '../models/subscription'
User = require '../models/user'
CacheService = require '../services/cache'
EmbedService = require '../services/embed'
PushNotificationService = require '../services/push_notification'
config = require '../config'

Tops =
  thread: require '../models/thread'
  campgroundReview: require '../models/campground_review'
  overnightReview: require '../models/overnight_review'

defaultEmbed = [
  EmbedService.TYPES.COMMENT.USER
  EmbedService.TYPES.COMMENT.GROUP_USER
  EmbedService.TYPES.COMMENT.TIME
]

MAX_LENGTH = 10000
TEN_MINUTES_SECONDS = 60 * 10
MAX_COMMENT_DEPTH = 3

# there's probably a cleaner / more efficial way to this
getCommentsTree = (comments, findParentId, options) ->
  options ?= {}
  {depth, sort, skip, limit, getUnmatched} = options
  depth ?= 0
  limit ?= 50
  skip ?= 0

  if depth > MAX_COMMENT_DEPTH
    return {comments: [], unmatched: comments}

  {matchedComments, unmatched} = _.groupBy comments, ({parentId}) ->
    if "#{parentId}" is "#{findParentId}"
    then 'matchedComments'
    else 'unmatched'

  commentsTree = _.map matchedComments, (comment) ->
    # for each map step, reduce size of unmatched
    {comments, unmatched} = getCommentsTree(
      unmatched, comment.id, _.defaults {
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
    comment.myVote = _.find commentVotes, ({parentId}) ->
      "#{parentId}" is "#{comment.id}"
    comment.children = embedMyVotes comment.children, commentVotes
    comment

class CommentCtrl
  checkIfBanned: (groupId, ipAddr, userId, router) ->
    unless groupId
      return Promise.resolve false
    ipAddr ?= 'n/a'
    Promise.all [
      Ban.getByGroupIdAndIp groupId, ipAddr, {preferCache: true}
      Ban.getByGroupIdAndUserId groupId, userId, {preferCache: true}
    ]
    .then ([bannedIp, bannedUserId]) ->
      if bannedIp?.ip or bannedUserId?.userId
        router.throw status: 403, 'unable to post'

  create: ({body, topId, topType, parentId, parentType}, {user, headers, connection}) =>
    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    body = body.trim()

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post...'

    if body?.length > MAX_LENGTH and not user?.flags?.isModerator
      router.throw status: 400, info: 'message is too long...'

    unless body
      router.throw status: 400, info: 'can\'t be empty'

    Tops[topType].getById topId, {preferCache: true, omitCounter: true}
    .then (top) =>
      @checkIfBanned top.groupId, ip, user.id, router
      .then ->
        Comment.upsert
          userId: user.id
          body: body
          topId: topId
          parentId: parentId
          parentType: parentType
      .tap ->
        EarnAction.completeActionsByUserId(
          userId
          ['socialPost', 'firstSocialPost']
        ).catch -> null

        User.getById top.userId
        .then (otherUser) ->
          PushNotificationService.send otherUser, {
            type: Subscription.TYPES.SOCIAL
            titleObj:
              key: "#{top.type}Replied.title"
            textObj:
              key: "#{top.type}Replied.text"
              replacements:
                name: User.getDisplayName(user)
                subject: top?.title
            data:
              path:
                {
                  key: top.type
                  params:
                    slug: top.slug
                }
          }
        prefix = CacheService.PREFIXES.COMMENTS_BY_TOP_ID_CATEGORY
        Promise.all [
          CacheService.deleteByCategory "#{prefix}:#{topId}"
        ]

  getAllByTopId: ({topId, sort, skip, limit, groupId}, {user}) ->
    sort ?= 'popular'
    skip ?= 0
    prefix = CacheService.PREFIXES.COMMENTS_BY_TOP_ID
    categoryPrefix = CacheService.PREFIXES.COMMENTS_BY_TOP_ID_CATEGORY
    key = "#{prefix}:#{topId}:#{sort}:#{skip}:#{limit}"
    category = "#{categoryPrefix}:#{topId}"
    CacheService.preferCache key, ->
      Comment.getAllByTopId topId
      .map EmbedService.embed {embed: defaultEmbed, options: {groupId}}
      .catch (err) ->
        console.log err
      .then (allComments) ->
        getCommentsTree allComments, topId, {sort, skip, limit}
    , {category, expireSeconds: TEN_MINUTES_SECONDS}
    .then (comments) ->
      comments = comments?.slice skip, skip + limit
      Vote.getAllByUserIdAndTopIdAndParentType user.id, topId, 'comment'
      .then (commentVotes) ->
        embedMyVotes comments, commentVotes

  flag: ({id}, {headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    # TODO
    Comment.getById id
    .then EmbedService.embed {
      embed: [EmbedService.TYPES.COMMENT.USER]
    }

  deleteByComment: ({comment, groupId}, {user}) ->
    permission = GroupUser.PERMISSIONS.DELETE_FORUM_COMMENT
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [permission]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      Comment.deleteByRow comment
      .tap ->
        prefix = CacheService.PREFIXES.COMMENTS_BY_TOP_ID_CATEGORY
        CacheService.deleteByCategory "#{prefix}:#{comment.topId}"

  deleteAllByGroupIdAndUserId: ({groupId, userId, topId}, {user}) ->
    permission = GroupUser.PERMISSIONS.DELETE_FORUM_COMMENT
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [permission]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      Comment.deleteAllByUserId userId
      .tap ->
        if topId
          prefix = CacheService.PREFIXES.COMMENTS_BY_TOP_ID_CATEGORY
          CacheService.deleteByCategory "#{prefix}:#{topId}"

module.exports = new CommentCtrl()
