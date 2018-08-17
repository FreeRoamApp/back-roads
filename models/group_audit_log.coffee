_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

config = require '../config'
cknex = require '../services/cknex'

ONE_DAY_SECONDS = 3600 * 24
THREE_HOURS_SECONDS = 3600 * 3
SIXTY_DAYS_SECONDS = 60 * 3600 * 24

defaultGroupAuditLog = (groupAuditLog) ->
  unless groupAuditLog?
    return null

  _.defaults groupAuditLog, {
    uuid: cknex.getTimeUuid()
  }


tables = [
  {
    name: 'group_audit_log_by_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      userUuid: 'uuid'
      groupUuid: 'uuid'
      actionText: 'text'
    primaryKey:
      partitionKey: ['groupUuid']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
]

class GroupAuditLogModel
  SCYLLA_TABLES: tables

  upsert: (groupAuditLog) ->
    groupAuditLog = defaultGroupAuditLog(
      groupAuditLog
    )

    cknex().update 'group_audit_log_by_uuid'
    .set _.omit groupAuditLog, [
      'groupUuid', 'uuid'
    ]
    .andWhere 'groupUuid', '=', groupAuditLog.groupUuid
    .andWhere 'uuid', '=', groupAuditLog.id
    .usingTTL SIXTY_DAYS_SECONDS
    .run()
    .then ->
      groupAuditLog

  getAllByGroupUuid: (groupUuid) ->
    cknex().select '*'
    .from 'group_audit_log_by_uuid'
    .where 'groupUuid', '=', groupUuid
    .limit 30
    .run()

module.exports = new GroupAuditLogModel()
