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
cknex = require '../services/cknex'
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
    # FIXME: pass groupId for groupUser embed. don't embed groupUser for pm
  }, ConversationMessage.defaultOutput(item)
  .then (item) ->
    # TODO: rm?
    if item?.user?.flags?.isChatBanned isnt true
      item

class ConversationMessageCtrl
  constructor: ->
    @cardBuilder = new cardBuilder {api: config.DEALER_API_URL}

  _checkRateLimit: (userId, isMedia, router) ->
    if isMedia
      key = "#{CacheService.PREFIXES.RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA}:#{userId}"
      rateLimit = RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA
      rateLimitExpireS = RATE_LIMIT_CONVERSATION_MESSAGES_MEDIA_EXPIRE_S
    else
      key = "#{CacheService.PREFIXES.RATE_LIMIT_CONVERSATION_MESSAGES_TEXT}:#{userId}"
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

  _checkIfBanned: (groupId, ipAddr, userId, router) ->
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

  _getMentions: (conversation, body, {user}) ->
    mentions = _.map _.uniq(body.match /\@[a-zA-Z0-9_-]+/g), (find) ->
      find.replace('@', '').toLowerCase()
    mentions = _.take mentions, 5 # so people don't abuse
    hasMentions = not _.isEmpty mentions
    mentionsEveryone = mentions.indexOf('everyone') isnt -1
    groupId = conversation.groupId

    Promise.all [
      (if hasMentions and conversation.groupId
        GroupRole.getAllByGroupId conversation.groupId, {preferCache: true}
      else
        Promise.resolve(null)
      )

      if groupId and mentionsEveryone
        permissions = [GroupUser.PERMISSIONS.MENTION_EVERYONE]
        GroupUser.hasPermissionByGroupIdAndUser groupId, user, permissions, {
          channelId: conversation.id
        }
      else
        Promise.resolve null
    ]
    .then ([roles, hasMentionEveryonePermission]) ->
      _.reduce mentions, (obj, mention) ->
        if mention is 'everyone' and not hasMentionEveryonePermission
          return obj
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
      (if conversation.groupId
        Group.getById conversation.groupId, {preferCache: true}
      else
        Promise.resolve null
      )

      Promise.map userMentions, (username) ->
        User.getByUsername username, {preferCache: true}
        .then (user) ->
          user?.id
    ]
    .then ([group, mentionUserIds]) ->
      mentionUserIds = _.filter mentionUserIds
      PushNotificationService.sendToConversation(
        conversation, {
          skipMe: true
          meUser: user
          text: pushBody
          mentionUserIds: mentionUserIds
          mentionRoles: roleMentions
          conversationMessage: conversationMessage
        }).catch (err) ->
          console.log 'push err', err

  _createCards: (body, isImage, conversationMessageId) =>
    urls = not isImage and body.match(URL_REGEX)

    (if _.isEmpty urls
      Promise.resolve null
    else
      @cardBuilder.create {
        url: urls[0]
        callbackUrl:
          "#{config.RADIOACTIVE_API_URL}/conversationMessage/#{conversationMessageId}/card"
      }
      .timeout CARD_BUILDER_TIMEOUT_MS
      .catch -> null
    )

  create: ({body, conversationId, clientId}, {user, headers, connection}) =>
    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post'

    if body?.length > MAX_LENGTH
      router.throw status: 400, info: 'message is too long...'

    isImage = body.match IMAGE_REGEX
    isMedia = isImage
    isLink = body.match URL_REGEX

    @_checkRateLimit user.id, isMedia, router
    .then ->
      Conversation.getById conversationId
      .catch (err) ->
        console.log 'err getting conversation', conversationId, body
        throw err
    .then EmbedService.embed {embed: defaultConversationEmbed}
    .tap (conversation) =>
      groupId = conversation.groupId
      (if groupId
        Promise.all [
          @_checkIfBanned groupId, ip, user.id, router
        ]
        .then ->
          permissions = [GroupUser.PERMISSIONS.SEND_MESSAGE]
          if isImage
            permissions = permissions.concat GroupUser.PERMISSIONS.SEND_IMAGE
          if isLink
            permissions = permissions.concat GroupUser.PERMISSIONS.SEND_LINK
          GroupUser.hasPermissionByGroupIdAndUser groupId, user, permissions, {
            channelId: conversationId
          }
      else
        Conversation.pmHasPermission conversation, user.id)
      .then (hasPermission) ->
        unless hasPermission
          router.throw status: 400, info: 'no permission'
    .then (conversation) =>
      groupId = conversation.groupId
      (if groupId
        Group.getById groupId, {preferCache: true}
      else
        Promise.resolve null)
      .then (group) =>
          conversationMessageId = cknex.getTimeUuid()

          @_createCards body, isImage, conversationMessageId
          .then ({card} = {}) ->
            groupId = conversation.groupId or 'private'
            ConversationMessage.upsert {
              id: conversationMessageId
              userId: user.id
              body: body
              clientId: clientId
              conversationId: conversationId
              groupId: conversation?.groupId
              card: card
            }, {
              prepareFn: (item) ->
                prepareFn item
            }
      .then (conversationMessage) =>
        userIds = conversation.userIds
        pickedConversation = _.pick conversation, [
          'userId', 'userIds', 'groupId', 'id'
        ]
        Conversation.upsert _.defaults(pickedConversation, {
          lastUpdateTime: new Date()
          isRead: false
        }), {userId: user.id}

        @_getMentions conversation, body, {user}
        .then ({userMentions, roleMentions}) =>
          @_sendPushNotifications {
            conversation, user, body, userMentions, roleMentions, isImage
            conversationMessage
          }
        null # don't block

  deleteById: ({id}, {user}) ->
    ConversationMessage.getById id
    .then (conversationMessage) ->
      Conversation.getById conversationMessage.conversationId
      .then (conversation) ->
        if conversation.groupId
          GroupUser.getByGroupIdAndUserId conversation.groupId, user.id
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
            User.getById conversationMessage.userId
            .then (otherUser) ->
              GroupAuditLog.upsert {
                groupId: conversation.groupId
                userId: user.id
                actionText: Language.get 'audit.deleteMessage', {
                  replacements:
                    name: User.getDisplayName otherUser
                  language: user.language
                }
              }
            ConversationMessage.deleteByConversationMessage conversationMessage

  deleteAllByGroupIdAndUserId: ({groupId, userId, duration}, {user}) ->
    if groupId
      GroupUser.getByGroupIdAndUserId groupId, user.id
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
        User.getById userId
        .then (otherUser) ->
          GroupAuditLog.upsert {
            groupId
            userId: user.id
            actionText: Language.get 'audit.deleteMessagesLast7d', {
              replacements:
                name: User.getDisplayName otherUser
              language: user.language
            }
          }
        ConversationMessage.deleteAllByGroupIdAndUserId groupId, userId, {duration}

  updateCard: ({body, params, headers}) ->
    radioactiveHost = config.RADIOACTIVE_API_URL.replace /https?:\/\//i, ''
    isPrivate = headers.host is radioactiveHost
    if isPrivate and body.secret is config.DEALER_SECRET
      ConversationMessage.updateById params.id, {card: body.card}, {prepareFn}

  unsubscribeByConversationId: ({conversationId}, {user}, {socket}) ->
    ConversationMessage.unsubscribeByConversationId conversationId, {socket}

  getLastTimeByMeAndConversationId: ({conversationId}, {user}, {socket}) ->
    ConversationMessage.getLastTimeByUserIdAndConversationId user.id, conversationId

  getAllByConversationId: (options, {user}, socketInfo) =>
    {conversationId, minId, maxId, isStreamed} = options
    {emit, socket, route} = socketInfo

    Conversation.getById conversationId, {preferCache: true}
    .then (conversation) =>
      (if conversation.groupId
        groupId = conversation.groupId
        permissions = [GroupUser.PERMISSIONS.READ_MESSAGE]
        GroupUser.hasPermissionByGroupIdAndUser groupId, user, permissions, {
          channelId: conversationId
        }
      else
        Conversation.pmHasPermission conversation, user.id)
      .then (hasPermission) =>
        unless hasPermission
          router.throw status: 401, info: 'unauthorized'

        limit = 25

        ConversationMessage.getAllByConversationId conversationId, {
          limit: limit
          minId: minId
          maxId: maxId
          isStreamed: isStreamed
          emit: emit
          socket: socket
          route: route
          reverse: true
          initialPostFn: (item) ->
            prepareFn item
        }

  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'cm'}
    )

module.exports = new ConversationMessageCtrl()
