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
    id: cknex.getTimeUuid()
  }


tables = [
  {
    name: 'group_audit_log_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      userId: 'uuid'
      groupId: 'uuid'
      actionText: 'text'
    primaryKey:
      partitionKey: ['groupId']
      clusteringColumns: ['id']
    withClusteringOrderBy: ['id', 'desc']
  }
]

class GroupAuditLogModel
  SCYLLA_TABLES: tables

  upsert: (groupAuditLog) ->
    groupAuditLog = defaultGroupAuditLog(
      groupAuditLog
    )

    cknex().update 'group_audit_log_by_id'
    .set _.omit groupAuditLog, [
      'groupId', 'id'
    ]
    .andWhere 'groupId', '=', groupAuditLog.groupId
    .andWhere 'id', '=', groupAuditLog.id
    .usingTTL SIXTY_DAYS_SECONDS
    .run()
    .then ->
      groupAuditLog

  getAllByGroupId: (groupId) ->
    cknex().select '*'
    .from 'group_audit_log_by_id'
    .where 'groupId', '=', groupId
    .limit 30
    .run()

module.exports = new GroupAuditLogModel()
