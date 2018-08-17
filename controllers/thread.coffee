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
YOUTUBE_ID_REGEX = ///
  (?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)
  ([^"&?\/ ]{11})
///i
IMGUR_ID_REGEX = /https?:\/\/(?:i\.)?imgur\.com(?:\/a)?\/(.*?)(?:[\.#\/].*|$)/i
STREAMABLE_ID_REGEX = /https?:\/\/streamable\.com\/([a-zA-Z0-9]+)/i


class ThreadCtrl
  checkIfBanned: (groupUuid, ipAddr, userUuid, router) ->
    ipAddr ?= 'n/a'
    Promise.all [
      Ban.getByGroupUuidAndIp groupUuid, ipAddr, {preferCache: true}
      Ban.getByGroupUuidAndUserUuid groupUuid, userUuid, {preferCache: true}
      Ban.isHoneypotBanned ipAddr, {preferCache: true}
    ]
    .then ([bannedIp, bannedUserUuid, isHoneypotBanned]) ->
      if bannedIp?.ip or bannedUserUuid?.userUuid or isHoneypotBanned
        router.throw
          status: 403
          info: "unable to post, banned #{userUuid}, #{ipAddr}"

  getAttachment: (body) ->
    if youtubeId = body?.match(YOUTUBE_ID_REGEX)?[1]
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

  upsert: ({thread, groupUuid, language}, {user, headers, connection}) =>
    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    thread.category ?= 'general'

    @checkIfBanned groupUuid, ip, user.uuid, router
    .then =>
      msPlayed = Date.now() - user.joinTime?.getTime()

      if user.flags.isChatBanned
        router.throw status: 400, info: 'unable to post...'

      if thread.data.body?.length > MAX_LENGTH and not user?.flags?.isModerator
        router.throw status: 400, info: 'message is too long...'

      if not thread.data.body or not thread.data.title
        router.throw status: 400, info: 'can\'t be empty'

      if thread.data.title.match /like si\b/i
        router.throw status: 400, info: 'title must not contain that phrase'

      unless thread.uuid
        thread.category ?= 'general'

      if user.flags?.isStar
        thread.category = 'news'

      images = new RegExp('\\!\\[(.*?)\\]\\(<?(.*?)( |\\))', 'gi').exec(
        thread.data.body
      )
      firstImageSrc = images?[2]
      thread.data.attachments = _.filter thread.data.attachments, ({persist}) ->
        not persist
      if firstImageSrc
        largeCdnImgRegex = /https:\/\/cdn\.wtf\/images\/fam\/cm\/(.*?)\.large/i
        firstImageSrc = firstImageSrc.replace(
          largeCdnImgRegex, 'https://cdn.wtf/images/fam/cm/$1.small'
        )
        thread.data.attachments.push {
          type: 'image', src: firstImageSrc
        }

      Promise.all [
        @getAttachment thread.data.body
        if thread.data.deck
          @addDeck thread.data.deck
        else
          Promise.resolve {}
      ]
      .then ([attachment, deckDiff]) =>
        if attachment
          thread.data.attachments.push attachment

        thread = _.defaultsDeep deckDiff, thread

        Group.getByUuid groupUuid
        .then (group) =>
          @validateAndCheckPermissions thread, {user}
          .then (thread) ->
            if thread.uuid
              Thread.upsert thread
              .then ->
                deckKey = CacheService.PREFIXES.THREAD_DECK + ':' + thread.uuid
                key = CacheService.PREFIXES.THREAD + ':' + thread.uuid
                Promise.all [
                  CacheService.deleteByKey deckKey
                  CacheService.deleteByKey key
                ]
                {uuid: thread.uuid}
            else
              Thread.upsert _.defaults thread, {
                userUuid: user.uuid
                groupUuid: group?.uuid or config.GROUPS.CLASH_ROYALE_EN.ID
              }
      .tap ->
        # TODO: groupUuid
        CacheService.deleteByCategory CacheService.PREFIXES.THREADS_CATEGORY

  validateAndCheckPermissions: (thread, {user}) ->
    if thread.uuid
      threadPromise = Thread.getByUuid thread.uuid
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
    {category, language, sort, maxUuid, skip, limit, groupUuid} = options

    if category is 'all'
      category = null

    key = CacheService.PREFIXES.THREADS_CATEGORY + ':' + [
      groupUuid, category, language, sort, skip, maxUuid, limit
    ].join(':')

    CacheService.preferCache key, ->
      Group.getByUuid groupUuid, {preferCache: true}
      Thread.getAll {
        category, sort, language, groupUuid, skip, maxUuid, limit
      }
      .map (thread) ->
        EmbedService.embed {
          embed: defaultEmbed
          options: {
            groupUuid
            userUuid: user.uuid
          }
        }, thread
      .map Thread.sanitize null
    , {
      expireSeconds: ONE_MINUTE_SECONDS
      category: CacheService.PREFIXES.THREADS_CATEGORY
    }
    .then (threads) ->
      if _.isEmpty threads
        return threads
      console.log 'threads', threads
      parents = _.map threads, ({uuid}) -> {type: 'thread', uuid}
      ThreadVote.getAllByUserUuidAndParents user.uuid, parents
      .then (threadVotes) ->
        threads = _.map threads, (thread) ->
          thread.myVote = _.find threadVotes, ({parentUuid}) ->
            "#{parentUuid}" is "#{thread.uuid}"
          thread
        threads

  getByUuid: ({uuid, language}, {user}) ->
    key = CacheService.PREFIXES.THREAD_WITH_EMBEDS_BY_UUID + ':' + uuid

    CacheService.preferCache key, ->
      Thread.getByUuid uuid
      .then EmbedService.embed {
        embed: defaultEmbed
        options:
          userUuid: user.uuid
      }
      .then Thread.sanitize null
    , {expireSeconds: ONE_MINUTE_SECONDS}
    .then (thread) ->
      ThreadVote.getByUserUuidAndParent user.uuid, {uuid, type: 'thread'}
      .then (myVote) ->
        thread.myVote = myVote
        thread

  getById: ({id, language}, {user}) =>
    key = CacheService.PREFIXES.THREAD_WITH_EMBEDS_BY_ID + ':' + uuid

    CacheService.preferCache key, ->
      Thread.getById id
      .then EmbedService.embed {
        embed: defaultEmbed,
        options:
          userUuid: user.uuid
      }
      .then Thread.sanitize null
    , {expireSeconds: ONE_MINUTE_SECONDS}
    .then (thread) ->
      ThreadVote.getByUserUuidAndParent user.uuid, {
        uuid: thread.uuid, type: 'thread'
      }
      .then (myVote) ->
        thread.myVote = myVote
        thread

  deleteByUuid: ({uuid}, {user}) ->
    Thread.getByUuid uuid
    .then (thread) ->
      permission = GroupUser.PERMISSIONS.DELETE_FORUM_THREAD
      GroupUser.hasPermissionByGroupUuidAndUser thread.groupUuid, user, [permission]
      .then (hasPermission) ->
        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'

        Thread.deleteByUuid uuid
        .tap ->
          CacheService.deleteByCategory CacheService.PREFIXES.THREADS_CATEGORY

  pinByUuid: ({uuid}, {user}) ->
    Thread.getByUuid uuid
    .then (thread) ->
      permission = GroupUser.PERMISSIONS.PIN_FORUM_THREAD
      GroupUser.hasPermissionByGroupUuidAndUser thread.groupUuid, user, [permission]
      .then (hasPermission) ->
        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'

        Thread.upsert {
          groupUuid: thread.groupUuid
          userUuid: thread.userUuid
          category: thread.category
          uuid: thread.uuid
          timeBucket: thread.timeBucket
          data: _.defaults {isPinned: true}, thread.data
        }
        .tap ->
          Thread.setPinnedThreadUuid uuid
          Promise.all [
            CacheService.deleteByCategory CacheService.PREFIXES.THREADS_CATEGORY
            CacheService.deleteByKey CacheService.PREFIXES.THREAD + ':' + uuid
          ]

  unpinByUuid: ({uuid}, {user}) ->
    Thread.getByUuid uuid
    .then (thread) ->
      permission = GroupUser.PERMISSIONS.PIN_FORUM_THREAD
      GroupUser.hasPermissionByGroupUuidAndUser thread.groupUuid, user, [permission]
      .then (hasPermission) ->
        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'

        Thread.upsert {
          groupUuid: thread.groupUuid
          userUuid: thread.userUuid
          category: thread.category
          uuid: thread.uuid
          timeBucket: thread.timeBucket
          data: _.defaults {isPinned: false}, thread.data
        }
        .tap ->
          Thread.deletePinnedThreadUuid uuid
          Promise.all [
            CacheService.deleteByCategory CacheService.PREFIXES.THREADS_CATEGORY
            CacheService.deleteByKey CacheService.PREFIXES.THREAD + ':' + uuid
          ]

module.exports = new ThreadCtrl()
