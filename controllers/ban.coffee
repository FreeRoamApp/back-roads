_ = require 'lodash'
router = require 'exoid-router'

User = require '../models/user'
GroupUser = require '../models/group_user'
ConversationMessage = require '../models/conversation_message'
ThreadComment = require '../models/comment'
Thread = require '../models/thread'
GroupAuditLog = require '../models/group_audit_log'
Ban = require '../models/ban'
Language = require '../models/language'
EmbedService = require '../services/embed'
config = require '../config'

BANNED_LIMIT = 15

class BanCtrl
  getByGroupIdAndUserId: ({groupId, userId} = {}, {user}) ->
    Ban.getByGroupIdAndUserId groupId, userId

  getAllByGroupId: ({groupId, duration} = {}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.TEMP_BAN_USER
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      groupId ?= config.MAIN_GROUP_ID
      duration ?= '24h'

      Ban.getAllByGroupIdAndDuration groupId, duration
      .map EmbedService.embed {
        embed: [
          EmbedService.TYPES.BAN.USER
          EmbedService.TYPES.BAN.BANNED_BY_USER
        ]
        options:
          groupId: groupId
      }

  banByGroupIdAndUserId: ({userId, groupId, duration, type}, {user}) ->
    permission = if duration is 'permanent' \
                 then GroupUser.PERMISSIONS.PERMA_BAN_USER
                 else GroupUser.PERMISSIONS.TEMP_BAN_USER
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [permission]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      ban = {userId, groupId, duration, bannedById: user.id}

      User.getById userId
      .then (otherUser) ->
        unless otherUser
          router.throw status: 404, info: 'User not found'
        if type is 'ip'
          ban.ip = otherUser.lastActiveIp or otherUser.ip
        if ban.ip?.indexOf('::ffff:10.') isnt -1
          delete ban.ip # TODO: remove. ignores local ips (which shouldn't happen)


        GroupAuditLog.upsert {
          groupId
          userId: user.id
          actionText: Language.get 'audit.ban', {
            replacements:
              name: User.getDisplayName otherUser
            language: user.language
          }
        }

        if user.username in ['austin', 'rachel']
          User.upsertByRow otherUser, {
            flags: _.defaults {isChatBanned: true}, otherUser.flags
          }

        Ban.upsert ban, {
          ttl: if duration is '24h' then 3600 * 24 else undefined
        }
    .then ->
      if groupId
        Promise.all [
          ConversationMessage.deleteAllByGroupIdAndUserId groupId, userId
          ThreadComment.deleteAllByUserId userId
          Thread.deleteAllByUserId userId
        ]

  unbanByGroupIdAndUserId: ({userId, groupId}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.UNBAN_USER
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      User.getById userId
      .then (otherUser) ->
        GroupAuditLog.upsert {
          groupId
          userId: user.id
          actionText: Language.get 'audit.unban', {
            replacements:
              name: User.getDisplayName otherUser
            language: user.language
          }
        }

        if user.username in ['austin', 'rachel']
          User.upsertByRow otherUser, {
            flags: _.defaults {isChatBanned: false}, otherUser.flags
          }

      Ban.deleteAllByGroupIdAndUserId groupId, userId

module.exports = new BanCtrl()
