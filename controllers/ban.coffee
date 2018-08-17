_ = require 'lodash'
router = require 'exoid-router'

User = require '../models/user'
GroupUser = require '../models/group_user'
ConversationMessage = require '../models/conversation_message'
ThreadComment = require '../models/thread_comment'
Thread = require '../models/thread'
GroupAuditLog = require '../models/group_audit_log'
Ban = require '../models/ban'
Language = require '../models/language'
EmbedService = require '../services/embed'
config = require '../config'

BANNED_LIMIT = 15

class BanCtrl
  getByGroupUuidAndUserUuid: ({groupUuid, userUuid} = {}, {user}) ->
    Ban.getByGroupUuidAndUserUuid groupUuid, userUuid

  getAllByGroupUuid: ({groupUuid, duration} = {}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.TEMP_BAN_USER
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      groupUuid ?= config.MAIN_GROUP_UUID
      duration ?= '24h'

      Ban.getAllByGroupUuidAndDuration groupUuid, duration
      .map EmbedService.embed {
        embed: [
          EmbedService.TYPES.BAN.USER
          EmbedService.TYPES.BAN.BANNED_BY_USER
        ]
        options:
          groupUuid: groupUuid
      }

  banByGroupUuidAndUserUuid: ({userUuid, groupUuid, duration, type}, {user}) ->
    permission = if duration is 'permanent' \
                 then GroupUser.PERMISSIONS.PERMA_BAN_USER
                 else GroupUser.PERMISSIONS.TEMP_BAN_USER
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [permission]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      ban = {userUuid, groupUuid, duration, bannedByUuid: user.uuid}

      User.getByUuid userUuid
      .then (otherUser) ->
        unless otherUser
          router.throw status: 404, info: 'User not found'
        if type is 'ip'
          ban.ip = otherUser.lastActiveIp or otherUser.ip
        if ban.ip?.indexOf('::ffff:10.') isnt -1
          delete ban.ip # TODO: remove. ignores local ips (which shouldn't happen)


        GroupAuditLog.upsert {
          groupUuid
          userUuid: user.uuid
          actionText: Language.get 'audit.ban', {
            replacements:
              name: User.getDisplayName otherUser
            language: user.language
          }
        }

        if user.username in ['ponkat', 'jaimejosuee']
          User.updateByUser otherUser, {flags: {isChatBanned: true}}

        Ban.upsert ban, {
          ttl: if duration is '24h' then 3600 * 24 else undefined
        }
    .then ->
      if groupUuid
        Promise.all [
          ConversationMessage.deleteAllByGroupUuidAndUserUuid groupUuid, userUuid
          ThreadComment.deleteAllByUserUuid userUuid
          Thread.deleteAllByUserUuid userUuid
        ]

  unbanByGroupUuidAndUserUuid: ({userUuid, groupUuid}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.UNBAN_USER
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      User.getByUuid userUuid
      .then (otherUser) ->
        GroupAuditLog.upsert {
          groupUuid
          userUuid: user.uuid
          actionText: Language.get 'audit.unban', {
            replacements:
              name: User.getDisplayName otherUser
            language: user.language
          }
        }

        if user.username in ['ponkat', 'jaimejosuee']
          User.updateByUser otherUser, {flags: {isChatBanned: false}}

      Ban.deleteAllByGroupUuidAndUserUuid groupUuid, userUuid

module.exports = new BanCtrl()
