_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
config = require '../config'
cknex = require '../services/cknex'

ONE_DAY_SECONDS = 3600 * 24
THREE_HOURS_SECONDS = 3600 * 3
SIXTY_DAYS_SECONDS = 60 * 3600 * 24

class GroupAuditLogModel extends Base
  getScyllaTables: ->
    [
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

  upsert: (groupAuditLog) =>
    super groupAuditLog, {ttl: SIXTY_DAYS_SECONDS}

  getAllByGroupId: (groupId) ->
    cknex().select '*'
    .from 'group_audit_log_by_id'
    .where 'groupId', '=', groupId
    .limit 30
    .run()

  defaultInput: (groupAuditLog) ->
    unless groupAuditLog?
      return null

    _.defaults groupAuditLog, {
      id: cknex.getTimeUuid()
    }

module.exports = new GroupAuditLogModel()
