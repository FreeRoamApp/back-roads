_ = require 'lodash'

User = require '../models/user'

class GroupAuditLogEmbed
  user: (groupAuditLog) ->
    if groupAuditLog.userUuid
      groupAuditLog.user = User.getById groupAuditLog.userUuid, {preferCache: true}
      .then User.sanitizePublic(null)

  time: (groupAuditLog) ->
    uuid = if typeof groupAuditLog.uuid is 'string' \
               then cknex.getTimeUuidFromString groupAuditLog.uuid
               else groupAuditLog.uuid
    groupAuditLog.time = uuid.getDate()


module.exports = new GroupAuditLogEmbed()
