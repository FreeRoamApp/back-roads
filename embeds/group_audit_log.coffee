_ = require 'lodash'

cknex = require '../services/cknex'
User = require '../models/user'

class GroupAuditLogEmbed
  user: (groupAuditLog) ->
    if groupAuditLog.userId
      groupAuditLog.user = User.getById groupAuditLog.userId, {preferCache: true}
      .then User.sanitizePublic(null)

  time: (groupAuditLog) ->
    cknex.getDateFromTimeUuid groupAuditLog.id


module.exports = new GroupAuditLogEmbed()
