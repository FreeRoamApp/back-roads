_ = require 'lodash'

GroupAuditLog = require '../models/group_audit_log'
GroupUser = require '../models/group_user'
EmbedService = require '../services/embed'

defaultEmbed = [
  EmbedService.TYPES.GROUP_AUDIT_LOG.USER
  EmbedService.TYPES.GROUP_AUDIT_LOG.TIME
]

class GroupAuditLogCtrl
  getAllByGroupUuid: ({groupUuid}, {user}) ->
    GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, [
      GroupUser.PERMISSIONS.READ_AUDIT_LOG
    ]
    .then (hasPermission) ->
      unless hasPermission
        router.throw status: 400, info: 'no permission'

      GroupAuditLog.getAllByGroupUuid groupUuid
      .map EmbedService.embed {embed: defaultEmbed}

module.exports = new GroupAuditLogCtrl()
