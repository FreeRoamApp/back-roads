_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'

UNREAD_TTL = 3600 * 24 * 365 # 1y
READ_TTL = 3600 * 24 * 7 # 1w

class NotificationModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'notifications_by_userId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          groupId: 'uuid'
          uniqueId: 'text' # used so there's not a bunch of dupe messages
          fromId: 'uuid'
          title: 'text'
          text: 'text'
          isRead: 'boolean'
          data: 'text' # JSON conversationId
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
        withClusteringOrderBy: [['id', 'desc']]
      }
      # chat notifications
      {
        name: 'notifications_by_userId_and_groupId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          groupId: 'uuid'
          uniqueId: 'text' # used so there's not a bunch of dupe messages
          fromId: 'uuid'
          title: 'text'
          text: 'text'
          isRead: 'boolean'
          data: 'text' # JSON conversationId
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['groupId', 'id']
        withClusteringOrderBy: [['groupId', 'desc'], ['id', 'desc']]
      }
      {
        name: 'notifications_by_roleId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          roleId: 'uuid'
          groupId: 'uuid'
          uniqueId: 'text' # used so there's not a bunch of dupe messages
          fromId: 'uuid'
          title: 'text'
          text: 'text'
          isRead: 'boolean'
          data: 'text' # JSON conversationId
        primaryKey:
          partitionKey: ['roleId']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'notifications_by_userId_and_uniqueId'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          groupId: 'uuid'
          uniqueId: 'text' # used so there's not a bunch of dupe messages
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['uniqueId']
      }
    ]

  upsert: (notification) =>
    notification = @defaultInput notification

    (if notification.uniqueId
      @getByUserIdAndUniqueId(
        notification.userId, notification.uniqueId
      )
      .tap (existingNotification) =>
        if existingNotification
          @deleteByNotification existingNotification
      .then ->
        delete notification.time
        notification
    else
      notification.uniqueId = uuid.v4()
      Promise.resolve notification
    )
    .then (notification) =>
      if notification.isRead
        ttl = READ_TTL
      else
        ttl = UNREAD_TTL

      super notification, {ttl}

  getAllByUserId: (userId, {limit} = {}) =>
    limit ?= 1000
    cknex().select '*'
    .from 'notifications_by_userId'
    .where 'userId', '=', userId
    .limit limit
    .run()
    .map @defaultOutput

  getByUserIdAndUniqueId: (userId, uniqueId) =>
    cknex().select '*'
    .from 'notifications_by_userId_and_uniqueId'
    .where 'userId', '=', userId
    .andWhere 'uniqueId', '=', uniqueId
    .run {isSingle: true}
    .then @defaultOutput

  getAllByUserIdAndGroupId: (userId, groupId) =>
    cknex().select '*'
    .from 'notifications_by_userId_and_groupId'
    .where 'userId', '=', userId
    .andWhere 'groupId', '=', groupId
    .run()
    .map @defaultOutput

  getAllByRoleId: (roleId) =>
    cknex().select '*'
    .from 'notifications_by_roleId'
    .where 'roleId', '=', roleId
    .run()
    .map @defaultOutput

  # TODO: super() (deleteByRow)
  deleteByNotification: (notification) ->
    Promise.all _.filter _.flatten [
      if notification.userId
        [
          cknex().delete()
          .from 'notifications_by_userId'
          .where 'userId', '=', notification.userId
          .andWhere 'id', '=', notification.id
          .run()

          cknex().delete()
          .from 'notifications_by_userId_and_groupId'
          .where 'userId', '=', notification.userId
          .andWhere 'groupId', '=', notification.groupId
          .andWhere 'id', '=', notification.id
          .run()

          cknex().delete()
          .from 'notifications_by_userId_and_uniqueId'
          .where 'userId', '=', notification.userId
          .andWhere 'uniqueId', '=', notification.uniqueId
          .run()
       ]

      if notification.roleId
        cknex().delete()
        .from 'notifications_by_roleId'
        .where 'roleId', '=', notification.roleId
        .andWhere 'id', '=', notification.id
        .run()
    ]

  defaultInput: (notification) ->
    unless notification?
      return null

    if notification.data
      notification.data = JSON.stringify notification.data

    Object.assign {id: cknex.getTimeUuid(), isRead: false}, notification

  defaultOutput: (notification) ->
    unless notification?
      return null

    if notification.data
      notification.data = try
        JSON.parse notification.data
      catch err
        {}

    notification.time = notification.id.getDate()

    notification

module.exports = new NotificationModel()
