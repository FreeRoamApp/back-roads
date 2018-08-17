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
  EmbedService.TYPES.GROUP_USER.KARMA
]
userEmbed = [
  EmbedService.TYPES.GROUP_USER.USER
]
class GroupUserCtrl
  addRoleByGroupUuidAndUserUuid: ({groupUuid, userUuid, roleUuid}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupRole.getAllByGroupUuid groupUuid
      .then (roles) ->
        role = _.find roles, (role) ->
          "#{role.roleUuid}" is "#{roleUuid}"
        unless role
          router.throw status: 404, info: 'no role exists'

        User.getByUuid userUuid
        .then (otherUser) ->
          GroupAuditLog.upsert {
            groupUuid
            userUuid: user.uuid
            actionText: Language.get 'audit.giveRole', {
              replacements:
                name: User.getDisplayName otherUser
                roleName: role.name
              language: user.language
            }
          }

        console.log 'add role'
        PushNotificationService.subscribeToPushTopic {
          userUuid, groupUuid, sourceType: 'role', sourceId: role.name
        }

        GroupUser.addRoleUuidByGroupUser {
          userUuid: userUuid
          groupUuid: groupUuid
        }, roleUuid

  removeRoleByGroupUuidAndUserUuid: ({groupUuid, userUuid, roleUuid}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'
      GroupRole.getAllByGroupUuid groupUuid
      .then (roles) ->
        role = _.find roles, (role) ->
          "#{role.roleUuid}" is "#{roleUuid}"
        unless role
          router.throw status: 404, info: 'no role exists'

        User.getByUuid userUuid
        .then (otherUser) ->
          GroupAuditLog.upsert {
            groupUuid
            userUuid: user.uuid
            actionText: Language.get 'audit.removeRole', {
              replacements:
                name: User.getDisplayName otherUser
                roleName: role.name
              language: user.language
            }
          }

        PushNotificationService.unsubscribeToTopicByPushTopic {
          userUuid, groupUuid, sourceType: 'role', sourceId: role.name
        }

        GroupUser.removeRoleUuidByGroupUser {
          userUuid: userUuid
          groupUuid: groupUuid
        }, roleUuid

  addKarmaByGroupUuidAndUserUuid: ({groupUuid, userUuid, karma}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.ADD_XP
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      User.getByUuid userUuid
      .then (otherUser) ->
        GroupAuditLog.upsert {
          groupUuid
          userUuid: user.uuid
          actionText: Language.get 'audit.giveKarma', {
            replacements:
              name: User.getDisplayName otherUser
              karma: karma
            language: user.language
          }
        }

        unless isNaN karma
          GroupUser.incrementKarmaByGroupUuidAndUserUuid groupUuid, userUuid, karma

  getByGroupUuidAndUserUuid: ({groupUuid, userUuid}, {user}) ->
    GroupUser.getByGroupUuidAndUserUuid groupUuid, userUuid
    .then EmbedService.embed {embed: defaultEmbed}

  getTopByGroupUuid: ({groupUuid}, {user}) ->
    key = "#{CacheService.PREFIXES.GROUP_USER_TOP}:#{groupUuid}"
    CacheService.preferCache key, ->
      GroupUser.getTopByGroupUuid groupUuid
      .map EmbedService.embed {embed: userEmbed}
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  getMeSettingsByGroupUuid: ({groupUuid}, {user}) ->
    Group.hasPermissionByUuidAndUserUuid groupUuid, user.uuid, {level: 'member'}
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupUser.getSettingsByGroupUuidAndUserUuid groupUuid, user.uuid

  updateMeSettingsByGroupUuid: ({groupUuid, globalNotifications}, {user}) ->
    Group.hasPermissionByUuidAndUserUuid groupUuid, user.uuid, {level: 'member'}
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupUser.getSettingsByGroupUuidAndUserUuid groupUuid, user.uuid
      .then (settings) ->
        GroupUser.upsertSettings {
          groupUuid, userUuid: user.uuid
          globalNotifications: _.defaults(
            globalNotifications, settings?.globalNotifications
          )
        }

  # getOnlineCountByGroupUuid: ({groupUuid}) ->
  #   if groupUuid
  #     GroupUsersOnline.getCountByGroupUuid groupUuid
  #   else
  #     0

module.ekarmaorts = new GroupUserCtrl()
