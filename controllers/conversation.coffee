_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

User = require '../models/user'
Conversation = require '../models/conversation'
Notification = require '../models/notification'
Group = require '../models/group'
GroupAuditLog = require '../models/group_audit_log'
GroupUser = require '../models/group_user'
Language = require '../models/language'
Event = require '../models/event'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.CONVERSATION.USERS]
lastMessageEmbed = [
  EmbedService.TYPES.CONVERSATION.LAST_MESSAGE
  EmbedService.TYPES.CONVERSATION.USERS
]

class ConversationCtrl
  create: ({userUuids, groupUuid, name, description}, {user}) ->
    userUuids ?= []
    userUuids = _.uniq userUuids.concat [user.uuid]

    name = name and _.kebabCase(name.toLowerCase()).replace(/[^0-9a-z-]/gi, '')

    if groupUuid
      conversation = Conversation.getByGroupUuidAndName groupUuid, name
      hasPermission = GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
        GroupUser.PERMISSIONS.MANAGE_INFO
      ]
      .then (hasPermission) ->
        unless hasPermission
          router.throw {status: 400, info: 'You don\'t have permission'}
        hasPermission
    else
      conversation = Conversation.getByUserUuids userUuids
      hasPermission = Promise.resolve true

    Promise.all [conversation, hasPermission]
    .then ([conversation, hasPermission]) ->
      if groupUuid
        GroupAuditLog.upsert {
          groupUuid
          userUuid: user.uuid
          actionText: Language.get 'audit.addChannel', {
            replacements:
              channel: name
            language: user.language
          }
        }
      return conversation or Conversation.upsert({
        userUuids
        groupUuid
        data: {name, description}
        type: if groupUuid then 'channel' else 'pm'
      }, {userUuid: user.uuid})

  updateByUuid: ({uuid, name, description}, {user}) ->
    name = name and _.kebabCase(name.toLowerCase()).replace(/[^0-9a-z-]/gi, '')

    Conversation.getByUuid uuid
    .tap (conversation) ->
      groupUuid = conversation.groupUuid
      GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
        GroupUser.PERMISSIONS.MANAGE_INFO
      ]
      .then (hasPermission) ->
        unless hasPermission
          router.throw {status: 400, info: 'You don\'t have permission'}
      .then ->
        GroupAuditLog.upsert {
          groupUuid: conversation.groupUuid
          userUuid: user.uuid
          actionText: Language.get 'audit.updateChannel', {
            replacements:
              channel: name or conversation.name
            language: user.language
          }
        }
        Conversation.upsert {
          uuid: conversation.uuid
          userUuid: conversation.userUuid
          groupUuid: conversation.groupUuid
          data: _.defaults {
            name, description
          }, conversation.data
        }

  getAll: ({}, {user}) ->
    Conversation.getAllByUserUuid user.uuid
    .map EmbedService.embed {embed: lastMessageEmbed}
    .map Conversation.sanitize null

  getAllByGroupUuid: ({groupUuid}, {user}) ->
    Promise.all [
      GroupUser.getByGroupUuidAndUserUuid groupUuid, user.uuid
      .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}

      Conversation.getAllByGroupUuid groupUuid

      Notification.getAllByUserUuidAndGroupUuid user.uuid, groupUuid
    ]
    .then ([meGroupUser, conversations, notifications]) ->
      conversations = _.filter conversations, (conversation) ->
        GroupUser.hasPermission {
          meGroupUser
          permissions: [GroupUser.PERMISSIONS.READ_MESSAGE]
          channelUuid: conversation.uuid
        }

      # TODO: more efficient solution?
      _.map conversations, (conversation) ->
        conversation = Conversation.sanitize null, conversation
        notificationCount = _.filter(notifications, ({data, isRead}) ->
          data?.conversationUuid is conversation.uuid and not isRead
        )?.length or 0
        _.defaults {notificationCount}, conversation

  markReadByUuid: ({uuid, groupUuid}, {user}) ->
    Notification.getAllByUserUuidAndGroupUuid user.uuid, groupUuid
    .then (notifications) ->
      conversationNotifications = _.filter notifications, ({data, isRead}) ->
        data?.conversationUuid is uuid and not isRead
      Promise.map conversationNotifications, (notification) ->
        Notification.upsert Object.assign notification, {isRead: true}


  getByUuid: ({uuid}, {user}) ->
    Conversation.getByUuid uuid
    .then EmbedService.embed {embed: defaultEmbed}
    .tap (conversation) ->
      Promise.all [
        if conversation.groupUuid
          groupUuid = conversation.groupUuid
          GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
            GroupUser.PERMISSIONS.READ_MESSAGE
          ], {channelUuid: uuid}
          .then (hasPermission) ->
            unless hasPermission
              router.throw status: 400, info: 'no permission'
        else if not _.find(conversation.userUuids, (userUuid) ->
          "#{userUuid}" is "#{user.uuid}"
        )
          router.throw status: 400, info: 'no permission'
          Promise.resolve null

        # TODO: different way to track if read (groups get too large)
        # should store lastReadTime on user for each group
        if conversation.groupUuid
          Promise.resolve null
        else
          Conversation.markRead conversation, user.uuid
      ]
    .then Conversation.sanitize null


module.exports = new ConversationCtrl()
