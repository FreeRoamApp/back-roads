_ = require 'lodash'
uuid = require 'uuid'
Promise = require 'bluebird'

cknex = require '../services/cknex'
CacheService = require '../services/cache'

UNREAD_TTL = 3600 * 24 * 365 # 1y
READ_TTL = 3600 * 24 * 7 # 1w

defaultNotification = (notification) ->
  unless notification?
    return null

  if notification.data
    notification.data = JSON.stringify notification.data

  Object.assign {id: cknex.getTimeUuid(), isRead: false}, notification

defaultNotificationOutput = (notification) ->
  unless notification?
    return null

  if notification.data
    notification.data = try
      JSON.parse notification.data
    catch err
      {}

  notification.time = notification.id.getDate()

  notification

###
notification when mentioned (@everyone seems pretty expensive...) FIXME: solution
  - could have a separate table for notifications_by_roleId and merge
    results. create new by_userId when the role one is read, and prefer user ones when merging

notification when self mentioned in conversation: easy

trade notification i guess by groupId for now
###

tables = [
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
      clusteringColumns: ['groupId', 'id']
    withClusteringOrderBy: [['groupId', 'desc'], ['id', 'desc']]
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
]

class NotificationModel
  SCYLLA_TABLES: tables

  upsert: (notification) =>
    notification = defaultNotification notification

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
    .then (notification) ->
      # FIXME: i think lodash or cassanknex is adding these, but can't find where...
      setUser = _.omit notification, ['userId', 'groupId', 'id']
      setRole = _.omit notification, ['roleId', 'id']
      delete setUser.get
      delete setUser.values
      delete setUser.keys
      delete setUser.forEach
      delete setRole.get
      delete setRole.values
      delete setRole.keys
      delete setRole.forEach

      if notification.isRead
        ttl = READ_TTL
      else
        ttl = UNREAD_TTL
      Promise.all _.filter _.flatten [
        if notification.userId
          [
            cknex().update 'notifications_by_userId'
            .set setUser
            .where 'userId', '=', notification.userId
            .andWhere 'groupId', '=', notification.groupId
            .andWhere 'id', '=', notification.id
            .usingTTL ttl
            .run()

            cknex().update 'notifications_by_userId_and_uniqueId'
            .set _.pick notification, ['id' ,'groupId']
            .where 'userId', '=', notification.userId
            .andWhere 'uniqueId', '=', notification.uniqueId
            .usingTTL ttl
            .run()
         ]

        if notification.roleId
          cknex().update 'notifications_by_roleId'
          .set setRole
          .where 'roleId', '=', notification.roleId
          .andWhere 'id', '=', notification.id
          .usingTTL ttl
          .run()
      ]
      .then ->
        notification

  getAllByUserId: (userId) ->
    cknex().select '*'
    .from 'notifications_by_userId'
    .where 'userId', '=', userId
    .run()
    .map defaultNotificationOutput

  getByUserIdAndUniqueId: (userId, uniqueId) ->
    cknex().select '*'
    .from 'notifications_by_userId_and_uniqueId'
    .where 'userId', '=', userId
    .andWhere 'uniqueId', '=', uniqueId
    .run {isSingle: true}
    .then defaultNotificationOutput

  getAllByUserIdAndGroupId: (userId, groupId) ->
    cknex().select '*'
    .from 'notifications_by_userId'
    .where 'userId', '=', userId
    .andWhere 'groupId', '=', groupId
    .run()
    .map defaultNotificationOutput

  getAllByRoleId: (roleId) ->
    cknex().select '*'
    .from 'notifications_by_roleId'
    .where 'roleId', '=', roleId
    .run()
    .map defaultNotificationOutput

  deleteByNotification: (notification) ->
    Promise.all _.filter _.flatten [
      if notification.userId
        [
          cknex().delete()
          .from 'notifications_by_userId'
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

module.exports = new NotificationModel()
