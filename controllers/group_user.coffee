_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

User = require '../models/user'
GroupAuditLog = require '../models/group_audit_log'
GroupUser = require '../models/group_user'
# GroupUsersOnline = require '../models/group_users_online'
GroupRole = require '../models/group_role'
Group = require '../models/group'
Language = require '../models/language'
EmbedService = require '../services/embed'
CacheService = require '../services/cache'
PushNotificationService = require '../services/push_notification'
config = require '../config'

FIVE_MINUTES_SECONDS = 60 * 5

defaultEmbed = [
  EmbedService.TYPES.GROUP_USER.ROLES
]
userEmbed = [
  EmbedService.TYPES.GROUP_USER.USER
]
class GroupUserCtrl
  addRoleByGroupIdAndUserId: ({groupId, userId, roleId}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupRole.getAllByGroupId groupId
      .then (roles) ->
        role = _.find roles, (role) ->
          "#{role.id}" is "#{roleId}"
        unless role
          router.throw status: 404, info: 'no role exists'

        User.getById userId
        .then (otherUser) ->
          GroupAuditLog.upsert {
            groupId
            userId: user.id
            actionText: Language.get 'audit.giveRole', {
              replacements:
                name: User.getDisplayName otherUser
                roleName: role.name
              language: user.language
            }
          }

        PushNotificationService.subscribeToPushTopic {
          userId, groupId, sourceType: 'role', sourceId: role.name
        }

        GroupUser.addRoleIdByGroupUser {
          userId: userId
          groupId: groupId
        }, roleId

  removeRoleByGroupIdAndUserId: ({groupId, userId, roleId}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'
      GroupRole.getAllByGroupId groupId
      .then (roles) ->
        role = _.find roles, (role) ->
          "#{role.id}" is "#{roleId}"
        unless role
          router.throw status: 404, info: 'no role exists'

        User.getById userId
        .then (otherUser) ->
          GroupAuditLog.upsert {
            groupId
            userId: user.id
            actionText: Language.get 'audit.removeRole', {
              replacements:
                name: User.getDisplayName otherUser
                roleName: role.name
              language: user.language
            }
          }

        PushNotificationService.unsubscribeToTopicByPushTopic {
          userId, groupId, sourceType: 'role', sourceId: role.name
        }

        GroupUser.removeRoleIdByGroupUser {
          userId: userId
          groupId: groupId
        }, roleId

  getByGroupIdAndUserId: ({groupId, userId}, {user}) ->
    GroupUser.getByGroupIdAndUserId groupId, userId
    .then EmbedService.embed {embed: defaultEmbed}

  getTopByGroupId: ({groupId}, {user}) ->
    key = "#{CacheService.PREFIXES.GROUP_USER_TOP}:#{groupId}"
    CacheService.preferCache key, ->
      GroupUser.getTopByGroupId groupId
      .map EmbedService.embed {embed: userEmbed}
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  getMeSettingsByGroupId: ({groupId}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.READ_MESSAGE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupUser.getSettingsByGroupIdAndUserId groupId, user.id

  updateMeSettingsByGroupId: ({groupId, globalNotifications}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.READ_MESSAGE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupUser.getSettingsByGroupIdAndUserId groupId, user.id
      .then (settings) ->
        GroupUser.upsertSettings {
          groupId, userId: user.id
          globalNotifications: _.defaults(
            globalNotifications, settings?.globalNotifications
          )
        }

  # getOnlineCountByGroupId: ({groupId}) ->
  #   if groupId
  #     GroupUsersOnline.getCountByGroupId groupId
  #   else
  #     0

module.exports = new GroupUserCtrl()
