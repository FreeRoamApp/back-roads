_ = require 'lodash'

User = require '../models/user'

class GroupAuditLogEmbed
  user: (groupAuditLog) ->
    if groupAuditLog.userId
      groupAuditLog.user = User.getById groupAuditLog.userId, {preferCache: true}
      .then User.sanitizePublic(null)

  time: (groupAuditLog) ->
    id = if typeof groupAuditLog.id is 'string' \
               then cknex.getTimeUuidFromString groupAuditLog.id
               else groupAuditLog.id
    groupAuditLog.time = id.getDate()


module.exports = new GroupAuditLogEmbed()
