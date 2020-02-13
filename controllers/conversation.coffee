_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

User = require '../models/user'
Conversation = require '../models/conversation'
ConversationMessage = require '../models/conversation_message'
Notification = require '../models/notification'
Group = require '../models/group'
GroupAuditLog = require '../models/group_audit_log'
GroupUser = require '../models/group_user'
Language = require '../models/language'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.CONVERSATION.USERS]
lastMessageEmbed = [
  EmbedService.TYPES.CONVERSATION.LAST_MESSAGE
  EmbedService.TYPES.CONVERSATION.USERS
]

class ConversationCtrl
  # TODO: cleanup, make more efficient
  create: ({userIds, groupId, name, description}, {user}) ->
    userIds ?= []
    userIds = _.uniq userIds.concat [user.id]

    name = name and _.kebabCase(name.toLowerCase()).replace(/[^0-9a-z-]/gi, '')

    if groupId
      conversation = Conversation.getByGroupIdAndName groupId, name
      GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
        GroupUser.PERMISSIONS.MANAGE_INFO
      ]
      .then (hasPermission) ->
        unless hasPermission
          router.throw {status: 400, info: 'You don\'t have permission'}
        hasPermission
    else
      conversation = Conversation.getByUserIds userIds
      hasPermission = Promise.resolve true

    Promise.all [conversation, hasPermission]
    .then ([conversation, hasPermission]) ->
      if groupId
        GroupAuditLog.upsert {
          groupId
          userId: user.id
          actionText: Language.get 'audit.addChannel', {
            replacements:
              channel: name
            language: user.language
          }
        }
      return conversation or Conversation.upsert({
        userIds
        groupId
        data: {name, description}
        type: if groupId then 'channel' else 'pm'
      }, {userId: user.id})

  updateById: ({id, name, description, isWelcomeChannel}, {user}) ->
    name = name and _.kebabCase(name.toLowerCase()).replace(/[^0-9a-z-]/gi, '')

    Conversation.getById id
    .tap (conversation) ->
      groupId = conversation.groupId
      GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
        GroupUser.PERMISSIONS.MANAGE_INFO
      ]
      .then (hasPermission) ->
        unless hasPermission
          router.throw {status: 400, info: 'You don\'t have permission'}
      .then ->
        GroupAuditLog.upsert {
          groupId: conversation.groupId
          userId: user.id
          actionText: Language.get 'audit.updateChannel', {
            replacements:
              channel: name or conversation.name
            language: user.language
          }
        }
        Promise.all _.filter [
          if isWelcomeChannel
            Group.getById groupId
            .then (group) ->
              Group.upsertByRow group, {
                data: _.defaults {
                  welcomeChannelId: id
                }, group.data
              }
          Conversation.upsert {
            id: conversation.id
            userId: conversation.userId
            groupId: conversation.groupId
            data: _.defaults {
              name, description
            }, conversation.data
          }
        ]

  getAll: ({}, {user}) ->
    limit = if user.username in ['austin', 'rachel'] then 200 else 25
    Conversation.getAllByUserId user.id, {limit, hasMessages: true}
    .map EmbedService.embed {embed: lastMessageEmbed}
    .map Conversation.sanitize null

  getAllByGroupId: ({groupId}, {user}) ->
    Promise.all [
      GroupUser.getByGroupIdAndUserId groupId, user.id
      .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}

      Conversation.getAllByGroupId groupId

      Notification.getAllByUserIdAndGroupId user.id, groupId
    ]
    .then ([meGroupUser, conversations, notifications]) ->
      conversations = _.filter conversations, (conversation) ->
        GroupUser.hasPermission {
          meGroupUser
          permissions: [GroupUser.PERMISSIONS.READ_MESSAGE]
          channelId: conversation.id
        }

      # TODO: more efficient solution?
      _.map conversations, (conversation) ->
        conversation = Conversation.sanitize null, conversation
        notificationCount = _.filter(notifications, ({data, isRead}) ->
          data?.conversationId is conversation.id and not isRead
        )?.length or 0
        _.defaults {notificationCount}, conversation

  markReadById: ({id, groupId}, {user}) ->
    Notification.getAllByUserIdAndGroupId user.id, groupId
    .then (notifications) ->
      conversationNotifications = _.filter notifications, ({data, isRead}) ->
        data?.conversationId is id and not isRead
      Promise.map conversationNotifications, (notification) ->
        Notification.upsert Object.assign notification, {isRead: true}

  _createWelcomeConversation: ({user}) ->
    # 0-7 go to austin, 89abcdef to rachel. ALSO in free-roam
    devUsername = 'austin' # if user?.id.substr(-1) > '7' then 'rachel' else 'austin'
    User.getByUsername devUsername
    .then (devUser) ->
      Conversation.getByUserIds [user.id, devUser.id]
      .then (existingConversation) ->
        if existingConversation
          return existingConversation
        Conversation.upsert({
          userIds: [user.id, devUser.id]
          data: {}
          type: 'pm'
          lastUpdateTime: new Date()

        }, {userId: user.id})
        .tap (conversation) ->
          # TODO: first message
          ConversationMessage.upsert {
            # id: conversationMessageId
            userId: devUser.id
            body: Language.get "conversations.welcome#{devUsername}", {
              file: 'strings'
            }
            # clientId: clientId
            conversationId: conversation.id
          }
    .then ({id}) -> id

  getById: ({id}, {user}) =>
    (if id is 'welcome'
      @_createWelcomeConversation {user}
    else
      Promise.resolve id)
    .then (id) ->
      Conversation.getById id
    .then EmbedService.embed {embed: defaultEmbed}
    .tap (conversation) ->
      Promise.all [
        if conversation.groupId
          groupId = conversation.groupId
          GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
            GroupUser.PERMISSIONS.READ_MESSAGE
          ], {channelId: id}
          .then (hasPermission) ->
            unless hasPermission
              router.throw status: 400, info: 'no permission'
        else if not _.find(conversation.userIds, (userId) ->
          "#{userId}" is "#{user.id}"
        )
          router.throw status: 400, info: 'no permission'
          Promise.resolve null

        # TODO: different way to track if read (groups get too large)
        # should store lastReadTime on user for each group
        if conversation.groupId
          Promise.resolve null
        else
          Conversation.markRead conversation, user.id
      ]
    .then Conversation.sanitize null

  setOrderByGroupId: ({groupId, order}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.MANAGE_CHANNEL
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw {status: 400, info: 'You don\'t have permission'}

      Promise.map order, (conversationId, rank) ->
        Conversation.upsert {
          groupId
          id: conversationId
          rank: rank + 1
        }

module.exports = new ConversationCtrl()
