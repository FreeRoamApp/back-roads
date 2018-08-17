_ = require 'lodash'
router = require 'exoid-router'
cardBuilder = require 'card-builder'
uuid = require 'node-uuid'
Promise = require 'bluebird'
Joi = require 'joi'

User = require '../models/user'
Ban = require '../models/ban'
Group = require '../models/group'
ConversationMessage = require '../models/conversation_message'
Conversation = require '../models/conversation'
GroupAuditLog = require '../models/group_audit_log'
GroupRole = require '../models/group_role'
GroupUser = require '../models/group_user'
Language = require '../models/language'
CacheService = require '../services/cache'
PushNotificationService = require '../services/push_notification'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
schemas = require '../schemas'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.CONVERSATION_MESSAGE.USER
  EmbedService.TYPES.CONVERSATION_MESSAGE.MENTIONED_USERS
  EmbedService.TYPES.CONVERSATION_MESSAGE.TIME
  EmbedService.TYPES.CONVERSATION_MESSAGE.GROUP_USER
]

MAX_CONVERSATION_USER_IDS = 20
URL_REGEX = /\b(https?):\/\/[-A-Z0-9+&@#/%?=~_|!:,.;]*[A-Z0-9+&@#/%=~_|]/gi
IMAGE_REGEX = /\!\[(.*?)\]\((.*?)\)/gi
CARD_BUILDER_TIMEOUT_MS = 1000
SMALL_IMAGE_SIZE = 200
MAX_LENGTH = 5000
ONE_DAY_SECONDS = 3600 * 24

RATE_LIMIT_CONVERSATION_MESSAGES_TEXT = 6
RATE_LIMIT_CONVERSATION_MESSAGES_TEXT_EXPIRE_S = 5

RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA = 2
RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA_EXPIRE_S = 10
# LARGE_IMAGE_SIZE = 1000

defaultConversationEmbed = [EmbedService.TYPES.CONVERSATION.USERS]
prepareFn = (item) ->
  EmbedService.embed {
    embed: defaultEmbed
  }, ConversationMessage.default(item)
  .then (item) ->
    # TODO: rm?
    if item?.user?.flags?.isChatBanned isnt true
      item

class ConversationMessageCtrl
  constructor: ->
    @cardBuilder = new cardBuilder {api: config.DEALER_API_URL}

  _checkRateLimit: (userUuid, isMedia, router) ->
    if isMedia
      key = "#{CacheService.PREFIXES.RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA}:#{userUuid}"
      rateLimit = RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA
      rateLimitExpireS = RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA_EXPIRE_S
    else
      key = "#{CacheService.PREFIXES.RATE_LIMIT_CONVERSATION_MESSAGES_TEXT}:#{userUuid}"
      rateLimit = RATE_LIMIT_CONVERSATION_MESSAGES_TEXT
      rateLimitExpireS = RATE_LIMIT_CONVERSATION_MESSAGES_TEXT_EXPIRE_S

    CacheService.get key
    .then (amount) ->
      amount ?= 0
      if amount >= rateLimit
        router.throw status: 429, info: 'too many requests'
      CacheService.set key, amount + 1, {
        expireSeconds: rateLimitExpireS
      }

  _checkIfBanned: (groupUuid, ipAddr, userUuid, router) ->
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

  _checkSlowMode: (conversation, userUuid, router) ->
    isSlowMode = conversation?.data?.isSlowMode
    slowModeCooldownSeconds = conversation?.data?.slowModeCooldown
    if isSlowMode and slowModeCooldownSeconds
      ConversationMessage.getLastTimeByUserUuidAndConversationUuid userUuid, conversation.uuid
      .then (lastMeMessageTime) ->
        msSinceLastMessage = Date.now() - lastMeMessageTime
        cooldownSecondsLeft = slowModeCooldownSeconds -
                                Math.floor(msSinceLastMessage / 1000)
        if cooldownSecondsLeft > 0
          router.throw status: 403, info: 'unable to post, slow'
    else
      Promise.resolve null

  _getMentions: (conversation, body) ->
    mentions = _.map _.uniq(body.match /\@[a-zA-Z0-9_-]+/g), (find) ->
      find.replace('@', '').toLowerCase()
    mentions = _.take mentions, 5 # so people don't abuse
    hasMentions = not _.isEmpty mentions

    (if hasMentions and conversation.groupUuid
      GroupRole.getAllByGroupUuid conversation.groupUuid, {preferCache: true}
    else
      Promise.resolve(null)
    )
    .then (roles) ->
      # TODO: match roles
      _.reduce mentions, (obj, mention) ->
        if _.find roles, {name: mention}
          obj.roleMentions.push mention
        else
          obj.userMentions.push mention
        obj
      , {roleMentions: [], userMentions: []}

  _sendPushNotifications: (options = {}) ->
    {conversation, conversationMessage, user, body, userMentions,
      roleMentions, isImage} = options

    pushBody = if isImage then '[image]' else body

    Promise.all [
      (if conversation.groupUuid
        Group.getByUuid conversation.groupUuid, {preferCache: true}
      else
        Promise.resolve null
      )

      Promise.map userMentions, (username) ->
        User.getByUsername username, {preferCache: true}
        .then (user) ->
          user?.uuid
    ]
    .then ([group, mentionUserUuids]) ->
      mentionUserUuids = _.filter mentionUserUuids
      PushNotificationService.sendToConversation(
        conversation, {
          skipMe: true
          meUser: user
          text: pushBody
          mentionUserUuids: mentionUserUuids
          mentionRoles: roleMentions
          conversationMessage: conversationMessage
        }).catch -> null

  _createCards: (body, isImage, conversationMessageUuid) =>
    urls = not isImage and body.match(URL_REGEX)

    (if _.isEmpty urls
      Promise.resolve null
    else
      @cardBuilder.create {
        url: urls[0]
        callbackUrl:
          "#{config.RADIOACTIVE_API_URL}/conversationMessage/#{conversationMessageUuid}/card"
      }
      .timeout CARD_BUILDER_TIMEOUT_MS
      .catch -> null
    )

  create: ({body, conversationUuid, clientUuid}, {user, headers, connection}) =>
    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    msPlayed = Date.now() - user.joinTime?.getTime()

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post'

    if body?.length > MAX_LENGTH
      router.throw status: 400, info: 'message is too long...'

    isImage = body.match IMAGE_REGEX
    isMedia = isImage
    isLink = body.match URL_REGEX

    @_checkRateLimit user.uuid, isMedia, router
    .then ->
      Conversation.getByUuid conversationUuid
      .catch (err) ->
        console.log 'err getting conversation', conversationUuid, body
        throw err
    .then EmbedService.embed {embed: defaultConversationEmbed}
    .then (conversation) =>
      (if conversation.groupUuid
        groupUuid = conversation.groupUuid

        GroupUsersOnline.upsert {userUuid: user.uuid, groupUuid}

        Promise.all [
          @_checkIfBanned groupUuid, ip, user.uuid, router
          @_checkSlowMode conversation, user.uuid, router
        ]
        .then ->
          permissions = [GroupUser.PERMISSIONS.SEND_MESSAGE]
          if isImage
            permissions = permissions.concat GroupUser.PERMISSIONS.SEND_IMAGE
          if isLink
            permissions = permissions.concat GroupUser.PERMISSIONS.SEND_LINK
          GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, permissions, {
            channelUuid: conversationUuid
          }
          .then (hasPermission) ->
            unless hasPermission
              router.throw status: 400, info: 'no permission'
        .then ->
          if groupUuid
            Group.getByUuid groupUuid, {preferCache: true}
          else
            Promise.resolve null


      else Promise.resolve null)
      .then (group) =>
        Conversation.hasPermission conversation, user.uuid
        .then (hasPermission) =>
          unless hasPermission
            router.throw status: 401, info: 'unauthorized'

          conversationMessageUuid = uuid.v4()

          @_createCards body, isImage, conversationMessageUuid
          .then ({card} = {}) ->
            groupUuid = conversation.groupUuid or 'private'
            ConversationMessage.upsert {
              uuid: conversationMessageUuid
              userUuid: user.uuid
              body: body
              clientUuid: clientUuid
              conversationUuid: conversationUuid
              groupUuid: conversation?.groupUuid
              card: card
            }, {
              prepareFn: (item) ->
                prepareFn item
            }
      .tap ->
        if conversation.data?.isSlowMode
          ConversationMessage.upsertSlowModeLog {
            userUuid: user.uuid, conversationUuid: conversation.uuid
          }
      .tap  ->
        (if conversation.groupUuid
          EarnAction.completeActionByGroupUuidAndUserUuid(
            conversation.groupUuid
            user.uuid
            'conversationMessage'
          )
          .catch -> null
        else
          Promise.resolve null
        )
        .then (rewards) ->
          {rewards}
      .then (conversationMessage) =>
        userUuids = conversation.userUuids
        pickedConversation = _.pick conversation, [
          'userUuid', 'userUuids', 'groupUuid', 'uuid'
        ]
        Conversation.upsert _.defaults(pickedConversation, {
          lastUpdateTime: new Date()
          isRead: false
        }), {userUuid: user.uuid}

        @_getMentions conversation, body
        .then ({userMentions, roleMentions}) =>
          @_sendPushNotifications {
            conversation, user, body, userMentions, roleMentions, isImage
            conversationMessage
          }
        null # don't block

  deleteByUuid: ({uuid}, {user}) ->
    ConversationMessage.getByUuid uuid
    .then (conversationMessage) ->
      Conversation.getByUuid conversationMessage.conversationUuid
      .then (conversation) ->
        if conversation.groupUuid
          GroupUser.getByGroupUuidAndUserUuid conversation.groupUuid, user.uuid
          .then EmbedService.embed {
            embed: [EmbedService.TYPES.GROUP_USER.ROLES]
          }
          .then (groupUser) ->
            hasPermission = GroupUser.hasPermission {
              meGroupUser: groupUser
              me: user
              permissions: [GroupUser.PERMISSIONS.DELETE_MESSAGE]
            }

            unless hasPermission
              router.throw
                status: 400, info: 'You don\'t have permission to do that'
          .then ->
            User.getByUuid conversationMessage.userUuid
            .then (otherUser) ->
              GroupAuditLog.upsert {
                groupUuid: conversation.groupUuid
                userUuid: user.uuid
                actionText: Language.get 'audit.deleteMessage', {
                  replacements:
                    name: User.getDisplayName otherUser
                  language: user.language
                }
              }
            ConversationMessage.deleteByConversationMessage conversationMessage

  deleteAllByGroupUuidAndUserUuid: ({groupUuid, userUuid, duration}, {user}) ->
    if groupUuid
      GroupUser.getByGroupUuidAndUserUuid groupUuid, user.uuid
      .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}
      .then (groupUser) ->
        permission = 'deleteMessage'
        hasPermission = GroupUser.hasPermission {
          meGroupUser: groupUser
          me: user
          permissions: [GroupUser.PERMISSIONS.DELETE_MESSAGE]
        }

        unless hasPermission
          router.throw
            status: 400, info: 'You don\'t have permission to do that'
      .then ->
        User.getByUuid userUuid
        .then (otherUser) ->
          GroupAuditLog.upsert {
            groupUuid
            userUuid: user.uuid
            actionText: Language.get 'audit.deleteMessagesLast7d', {
              replacements:
                name: User.getDisplayName otherUser
              language: user.language
            }
          }
        ConversationMessage.deleteAllByGroupUuidAndUserUuid groupUuid, userUuid, {duration}

  updateCard: ({body, params, headers}) ->
    radioactiveHost = config.RADIOACTIVE_API_URL.replace /https?:\/\//i, ''
    isPrivate = headers.host is radioactiveHost
    if isPrivate and body.secret is config.DEALER_SECRET
      ConversationMessage.updateByUuid params.uuid, {card: body.card}, {prepareFn}

  unsubscribeByConversationUuid: ({conversationUuid}, {user}, {socket}) ->
    ConversationMessage.unsubscribeByConversationUuid conversationUuid, {socket}

  getLastTimeByMeAndConversationUuid: ({conversationUuid}, {user}, {socket}) ->
    ConversationMessage.getLastTimeByUserUuidAndConversationUuid user.uuid, conversationUuid

  getAllByConversationUuid: (options, {user}, socketInfo) =>
    {conversationUuid, minUuid, maxUuid, isStreamed} = options
    {emit, socket, route} = socketInfo

    Conversation.getByUuid conversationUuid, {preferCache: true}
    .then (conversation) =>

      Promise.all [
        if conversation.groupUuid
          Group.getByUuid conversation.groupUuid, {preferCache: true}
        else
          Promise.resolve null

        (if conversation.groupUuid
          groupUuid = conversation.groupUuid
          permissions = [GroupUser.PERMISSIONS.READ_MESSAGE]
          GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, permissions, {
            channelUuid: conversationUuid
          }
        else
          Conversation.hasPermission conversation, user.uuid)
      ]
      .then ([group, hasPermission]) =>
        unless hasPermission
          router.throw status: 401, info: 'unauthorized'

        limit = 25

        ConversationMessage.getAllByConversationUuid conversationUuid, {
          limit: limit
          minUuid: minUuid
          maxUuid: maxUuid
          isStreamed: isStreamed
          emit: emit
          socket: socket
          route: route
          reverse: true
          initialPostFn: (item) ->
            prepareFn item
        }


  uploadImage: ({}, {user, file}) ->
    router.assert {file}, {
      file: Joi.object().unknown().keys schemas.imageFile
    }
    ImageService.getSizeByBuffer (file.buffer)
    .then (size) ->
      key = "#{user.uuid}_#{uuid.v4()}"
      keyPrefix = "images/fam/cm/#{key}"

      aspectRatio = size.width / size.height
      # 10 is to prevent super wide/tall images from being uploaded
      if (aspectRatio < 1 and aspectRatio < 10) or aspectRatio < 0.1
        smallWidth = SMALL_IMAGE_SIZE
        smallHeight = smallWidth / aspectRatio
      else
        smallHeight = SMALL_IMAGE_SIZE
        smallWidth = smallHeight * aspectRatio

      Promise.all [
        ImageService.uploadImage
          key: "#{keyPrefix}.small.jpg"
          stream: ImageService.toStream
            buffer: file.buffer
            width: Math.min size.width, smallWidth
            height: Math.min size.height, smallHeight
            useMin: true

        ImageService.uploadImage
          key: "#{keyPrefix}.large.jpg"
          stream: ImageService.toStream
            buffer: file.buffer
            width: Math.min size.width, smallWidth * 5
            height: Math.min size.height, smallHeight * 5
            useMin: true
      ]
      .then (imageKeys) ->
        _.map imageKeys, (imageKey) ->
          "https://#{config.CDN_HOST}/#{imageKey}"
      .then ([smallUrl, largeUrl]) ->
        {smallUrl, largeUrl, key, width: size.width, height: size.height}

module.exports = new ConversationMessageCtrl()
