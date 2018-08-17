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
  getAllByGroupUuid: ({groupUuid}, {user}) ->
    GroupRole.getAllByGroupUuid groupUuid

  createByGroupUuid: ({groupUuid, name}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupAuditLog.upsert {
        groupUuid: groupUuid
        userUuid: user.uuid
        actionText: Language.get 'audit.addRole', {
          replacements:
            role: name
          language: user.language
        }
      }

      GroupRole.upsert {
        groupUuid: groupUuid
        name: name
        globalPermissions: {}
      }

  deleteByGroupUuidAndRoleUuid: ({groupUuid, roleUuid}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.MANAGE_ROLE
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupRole.getByGroupUuidAndRoleUuid groupUuid, roleUuid
      .then (role) ->
        GroupAuditLog.upsert {
          groupUuid: groupUuid
          userUuid: user.uuid
          actionText: Language.get 'audit.deleteRole', {
            replacements:
              role: role.name
            language: user.language
          }
        }

      GroupRole.deleteByGroupUuidAndRoleUuid groupUuid, roleUuid
      .tap ->
        prefix = CacheService.PREFIXES.GROUP_ROLES
        key = "#{prefix}:#{groupUuid}"
        CacheService.deleteByKey key

  updatePermissions: (params, {user}) ->
    {groupUuid, roleUuid, channelUuid, permissions} = params

    isSettingAdminPermission = permissions.admin

    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, _.filter [
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
            "#{channelUuid}": JSON.stringify permissions
      }
      diff = {
        groupUuid
        roleUuid
      }
      if not channelUuid
        diff.globalPermissions = permissions

      Promise.all [
        if channelUuid
        then Conversation.getByUuid channelUuid
        else Promise.resolve null

        GroupRole.getByGroupUuidAndRoleUuid groupUuid, roleUuid
      ]
      .then ([channel, role]) ->
        languageKey = if channel \
                      then 'audit.updateRoleChannel'
                      else 'audit.updateRole'
        GroupAuditLog.upsert {
          groupUuid
          userUuid: user.uuid
          actionText: Language.get languageKey, {
            replacements:
              role: role.name
              channel: channel?.name
            language: user.language
          }
        }

      GroupRole.upsert diff, if channelUuid then mapOptions else undefined
      .tap ->
        prefix = CacheService.PREFIXES.GROUP_ROLES
        key = "#{prefix}:#{groupUuid}"
        CacheService.deleteByKey key

module.exports = new GroupRoleCtrl()
