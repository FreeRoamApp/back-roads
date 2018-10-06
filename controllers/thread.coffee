_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'
request = require 'request-promise'
uuid = require 'uuid'

User = require '../models/user'
Group = require '../models/group'
GroupUser = require '../models/group_user'
Thread = require '../models/thread'
ThreadVote = require '../models/thread_vote'
Ban = require '../models/ban'
CacheService = require '../services/cache'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.THREAD.USER
  EmbedService.TYPES.THREAD.COMMENT_COUNT
]

MAX_LENGTH = 100000
ONE_MINUTE_SECONDS = 60
IMAGE_REGEX = /\!\[(.*?)\]\((.*?)\)/gi
IMGUR_ID_REGEX = /https?:\/\/(?:i\.)?imgur\.com(?:\/a)?\/(.*?)(?:[\.#\/].*|$)/i
STREAMABLE_ID_REGEX = /https?:\/\/streamable\.com\/([a-zA-Z0-9]+)/i


class ThreadCtrl
  checkIfBanned: (groupId, ipAddr, userId, router) ->
    ipAddr ?= 'n/a'
    Promise.all [
      Ban.getByGroupIdAndIp groupId, ipAddr, {preferCache: true}
      Ban.getByGroupIdAndUserId groupId, userId, {preferCache: true}
      Ban.isHoneypotBanned ipAddr, {preferCache: true}
    ]
    .then ([bannedIp, bannedUserId, isHoneypotBanned]) ->
      if bannedIp?.ip or bannedUserId?.userId or isHoneypotBanned
        router.throw
          status: 403
          info: "unable to post, banned #{userId}, #{ipAddr}"

  getAttachment: (body) ->
    if youtubeId = body?.match(config.YOUTUBE_ID_REGEX)?[2]
      return Promise.resolve {
        type: 'video'
        src: "https://www.youtube.com/embed/#{youtubeId}?autoplay=1"
        previewSrc: "https://img.youtube.com/vi/#{youtubeId}/maxresdefault.jpg"
      }
    else if imgurId = body?.match(IMGUR_ID_REGEX)?[1]
      if body?.match /\.(gif|mp4|webm)/i
        return Promise.resolve {
          type: 'video'
          src: "https://i.imgur.com/#{imgurId}.mp4"
          previewSrc: "https://i.imgur.com/#{imgurId}h.jpg"
          mp4Src: "https://i.imgur.com/#{imgurId}.mp4"
          webmSrc: "https://i.imgur.com/#{imgurId}.webm"
        }
      else
        return Promise.resolve {
          type: 'image'
          src: "https://i.imgur.com/#{imgurId}.jpg"
        }
    else if streamableId = body?.match(STREAMABLE_ID_REGEX)?[1]
      return request "https://api.streamable.com/videos/#{streamableId}", {
        json: true
      }
      .then (data) ->
        paddingBottom = data.embed_code?.match(
          /padding-bottom: ([0-9]+\.?[0-9]*%)/i
        )?[1]
        aspectRatio = 100 / parseInt(paddingBottom)
        if isNaN aspectRatio
          aspectRatio = 1.777 # 16:9
        {
          type: 'video'
          src: "https://streamable.com/o/#{streamableId}"
          previewSrc: data.thumbnail_url
          aspectRatio: aspectRatio
        }
    else
      return Promise.resolve null

  upsert: ({thread, groupId, language}, {user, headers, connection}) =>
    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    thread.category ?= 'general'

    @checkIfBanned groupId, ip, user.id, router
    .then =>
      if user.flags.isChatBanned
        router.throw status: 400, info: 'unable to post...'

      if thread.body?.length > MAX_LENGTH and not user?.flags?.isModerator
        router.throw status: 400, info: 'message is too long...'

      if not thread.body or not thread.title
        router.throw status: 400, info: 'can\'t be empty'

      if thread.title.match /like si\b/i
        router.throw status: 400, info: 'title must not contain that phrase'

      unless thread.id
        thread.category ?= 'general'

      if user.flags?.isStar
        thread.category = 'news'

      images = new RegExp('\\!\\[(.*?)\\]\\(<?(.*?)( |\\))', 'gi').exec(
        thread.body
      )
      firstImageSrc = images?[2]
      thread.attachments = _.filter thread.attachments, ({persist}) ->
        not persist
      if firstImageSrc
        largeCdnImgRegex = /https:\/\/cdn\.wtf\/images\/th\/(.*?)\.large/i
        firstImageSrc = firstImageSrc.replace(
          largeCdnImgRegex, "https://#{config.CDN_HOST}/images/th/$1.small"
        )
        thread.attachments.push {
          type: 'image', src: firstImageSrc
        }

      @getAttachment thread.body
      .then (attachment) =>
        if attachment
          thread.attachments.push attachment

        Group.getById groupId
        .then (group) =>
          @validateAndCheckPermissions thread, {user}
          .then (thread) ->
            if thread.id
              Thread.upsert thread
              .then ->
                key = CacheService.PREFIXES.THREAD + ':' + thread.id
                Promise.all [
                  CacheService.deleteByKey key
                ]
                {id: thread.id}
            else
              Thread.upsert _.defaults thread, {
                userId: user.id
                groupId: group?.id
              }
      .tap ->
        {category} = thread
        CacheService.deleteByCategory(
          "#{CacheService.PREFIXES.THREADS_CATEGORY}:#{groupId}:#{category}"
        )
        CacheService.deleteByCategory(
          "#{CacheService.PREFIXES.THREAD_BY_ID_CATEGORY}:#{thread.id}"
        )
        CacheService.deleteByCategory(
          "#{CacheService.PREFIXES.THREAD_BY_SLUG_CATEGORY}:#{thread.slug}"
        )

  validateAndCheckPermissions: (thread, {user}) ->
    if thread.id
      threadPromise = Thread.getById thread.id
      hasPermission = threadPromise.then (existingThread) ->
        Thread.hasPermission existingThread, user, {
          level: 'member'
        }
    else
      hasPermission = Promise.resolve true

    Promise.all [
      threadPromise
      hasPermission
    ]
    .then ([existingThread, hasPermission]) ->
      thread = _.defaultsDeep thread, existingThread

      unless hasPermission
        router.throw status: 400, info: 'no permission'
      thread

  getAll: (options, {user}) ->
    {category, language, sort, maxId, skip, limit, groupId} = options

    if category is 'all'
      category = null

    key = CacheService.PREFIXES.THREADS_BY_CATEGORY + ':' + [
      groupId, category, language, sort, skip, maxId, limit
    ].join(':')

    CacheService.preferCache key, ->
      Group.getById groupId, {preferCache: true}
      Thread.getAll {
        category, sort, language, groupId, skip, maxId, limit
      }
      .map (thread) ->
        EmbedService.embed {
          embed: defaultEmbed
          options: {
            groupId
            userId: user.id
          }
        }, thread
      .map Thread.sanitize null
    , {
      expireSeconds: ONE_MINUTE_SECONDS
      category:
        "#{CacheService.PREFIXES.THREADS_CATEGORY}:#{groupId}:#{category}"
    }
    .then (threads) ->
      if _.isEmpty threads
        return threads
      parents = _.map threads, ({id}) -> {type: 'thread', id}
      ThreadVote.getAllByUserIdAndParents user.id, parents
      .then (threadVotes) ->
        threads = _.map threads, (thread) ->
          thread.myVote = _.find threadVotes, ({parentId}) ->
            "#{parentId}" is "#{thread.id}"
          thread
        threads

  getById: ({id, language}, {user}) ->
    key = CacheService.PREFIXES.THREAD_WITH_EMBEDS_BY_ID + ':' + id

    CacheService.preferCache key, ->
      Thread.getById id
      .then EmbedService.embed {
        embed: defaultEmbed
        options:
          userId: user.id
      }
      .then Thread.sanitize null
    , {
      expireSeconds: ONE_MINUTE_SECONDS
      category: "#{CacheService.PREFIXES.THREAD_BY_ID_CATEGORY}:#{id}"
    }
    .then (thread) ->
      ThreadVote.getByUserIdAndParent user.id, {id, type: 'thread'}
      .then (myVote) ->
        thread.myVote = myVote
        thread

  getBySlug: ({slug, language}, {user}) =>
    key = CacheService.PREFIXES.THREAD_WITH_EMBEDS_BY_SLUG + ':' + slug

    CacheService.preferCache key, ->
      Thread.getBySlug slug
      .then EmbedService.embed {
        embed: defaultEmbed,
        options:
          userId: user.id
      }
      .then Thread.sanitize null
    , {
      expireSeconds: ONE_MINUTE_SECONDS
      category: "#{CacheService.PREFIXES.THREAD_BY_SLUG_CATEGORY}:#{slug}"
    }
    .then (thread) ->
      ThreadVote.getByUserIdAndParent user.id, {
        id: thread.id, type: 'thread'
      }
      .then (myVote) ->
        thread.myVote = myVote
        thread

  deleteById: ({id}, {user}) ->
    Thread.getById id
    .then (thread) ->
      permission = GroupUser.PERMISSIONS.DELETE_FORUM_THREAD
      GroupUser.hasPermissionByGroupIdAndUser thread.groupId, user, [permission]
      .then (hasPermission) ->
        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'

        Thread.deleteById id
        .tap ->
          {groupId, category} = thread
          CacheService.deleteByCategory(
            "#{CacheService.PREFIXES.THREADS_CATEGORY}:#{groupId}:#{category}"
          )
          CacheService.deleteByCategory(
            "#{CacheService.PREFIXES.THREAD_BY_ID_CATEGORY}:#{id}"
          )
          CacheService.deleteByCategory(
            "#{CacheService.PREFIXES.THREAD_BY_SLUG_CATEGORY}:#{thread.slug}"
          )

  pinById: ({id}, {user}) ->
    Thread.getById id
    .then (thread) ->
      permission = GroupUser.PERMISSIONS.PIN_FORUM_THREAD
      GroupUser.hasPermissionByGroupIdAndUser thread.groupId, user, [permission]
      .then (hasPermission) ->
        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'

        Thread.upsert {
          groupId: thread.groupId
          userId: thread.userId
          category: thread.category
          id: thread.id
          timeBucket: thread.timeBucket
          isPinned: true
        }
        .tap ->
          Thread.setPinnedThreadId id
          {groupId, category} = thread
          Promise.all [
            CacheService.deleteByCategory(
              "#{CacheService.PREFIXES.THREADS_CATEGORY}:#{groupId}:#{category}"
            )
            CacheService.deleteByCategory(
              "#{CacheService.PREFIXES.THREAD_BY_ID_CATEGORY}:#{id}"
            )
            CacheService.deleteByCategory(
              "#{CacheService.PREFIXES.THREAD_BY_SLUG_CATEGORY}:#{thread.slug}"
            )
          ]

  unpinById: ({id}, {user}) ->
    Thread.getById id
    .then (thread) ->
      permission = GroupUser.PERMISSIONS.PIN_FORUM_THREAD
      GroupUser.hasPermissionByGroupIdAndUser thread.groupId, user, [permission]
      .then (hasPermission) ->
        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'

        Thread.upsert {
          groupId: thread.groupId
          userId: thread.userId
          category: thread.category
          id: thread.id
          timeBucket: thread.timeBucket
          isPinned: false
        }
        .tap ->
          {groupId, category} = thread
          Thread.deletePinnedThreadId id
          Promise.all [
            CacheService.deleteByCategory(
              "#{CacheService.PREFIXES.THREADS_CATEGORY}:#{groupId}:#{category}"
            )
            CacheService.deleteByCategory(
              "#{CacheService.PREFIXES.THREAD_BY_ID_CATEGORY}:#{id}"
            )
            CacheService.deleteByCategory(
              "#{CacheService.PREFIXES.THREAD_BY_SLUG_CATEGORY}:#{thread.slug}"
            )
          ]

    uploadImage: ({}, {user, file}) ->
      ImageService.uploadImageByUserIdAndFile(
        user.id, file, {folder: 'th'}
      )

module.exports = new ThreadCtrl()
