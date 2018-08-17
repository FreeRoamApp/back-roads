_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

Conversation = require '../models/conversation'
GroupRole = require '../models/group_role'
GroupUser = require '../models/group_user'
GroupAuditLog = require '../models/group_audit_log'
Language = require '../models/language'
CacheService = require '../services/cache'
config = require '../config'

class GroupRoleCtrl
  getAllByGroupId: ({groupId}, {user}) ->
    GroupRole.getAllByGroupId groupId

  createByGroupId: ({groupId, name}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupAuditLog.upsert {
        groupId: groupId
        userId: user.id
        actionText: Language.get 'audit.addRole', {
          replacements:
            role: name
          language: user.language
        }
      }

      GroupRole.upsert {
        groupId: groupId
        name: name
        globalPermissions: {}
      }

  deleteByGroupIdAndRoleId: ({groupId, roleId}, {user}) ->
    GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupRole.getByGroupIdAndRoleId groupId, roleId
      .then (role) ->
        GroupAuditLog.upsert {
          groupId: groupId
          userId: user.id
          actionText: Language.get 'audit.deleteRole', {
            replacements:
              role: role.name
            language: user.language
          }
        }

      GroupRole.deleteByGroupIdAndRoleId groupId, roleId
      .tap ->
        prefix = CacheService.PREFIXES.GROUP_ROLES
        key = "#{prefix}:#{groupId}"
        CacheService.deleteByKey key

  updatePermissions: (params, {user}) ->
    {groupId, roleId, channelId, permissions} = params

    isSettingAdminPermission = permissions.admin

    GroupUser.hasPermissionByGroupIdAndUser groupId, user, _.filter [
      GroupUser.PERMISSIONS.MANAGE_ROLE
      if isSettingAdminPermission
        GroupUser.PERMISSIONS.ADMIN
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      mapOptions = {
        map:
          channelPermissions:
            "#{channelId}": JSON.stringify permissions
      }
      diff = {
        groupId
        roleId
      }
      if not channelId
        diff.globalPermissions = permissions

      Promise.all [
        if channelId
        then Conversation.getById channelId
        else Promise.resolve null

        GroupRole.getByGroupIdAndRoleId groupId, roleId
      ]
      .then ([channel, role]) ->
        languageKey = if channel \
                      then 'audit.updateRoleChannel'
                      else 'audit.updateRole'
        GroupAuditLog.upsert {
          groupId
          userId: user.id
          actionText: Language.get languageKey, {
            replacements:
              role: role.name
              channel: channel?.name
            language: user.language
          }
        }

      GroupRole.upsert diff, if channelId then mapOptions else undefined
      .tap ->
        prefix = CacheService.PREFIXES.GROUP_ROLES
        key = "#{prefix}:#{groupId}"
        CacheService.deleteByKey key

module.exports = new GroupRoleCtrl()
