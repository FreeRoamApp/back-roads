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

  Object.assign {uuid: cknex.getTimeUuid(), isRead: false}, notification

defaultNotificationOutput = (notification) ->
  unless notification?
    return null

  if notification.data
    notification.data = try
      JSON.parse notification.data
    catch err
      {}

  notification.time = notification.uuid.getDate()

  notification

###
notification when mentioned (@everyone seems pretty expensive...) FIXME: solution
  - could have a separate table for notifications_by_roleUuid and merge
    results. create new by_userUuid when the role one is read, and prefer user ones when merging

notification when self mentioned in conversation: easy

trade notification i guess by groupUuid for now
###

tables = [
  {
    name: 'notifications_by_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      userUuid: 'uuid'
      groupUuid: 'uuid'
      uniqueId: 'text' # used so there's not a bunch of dupe messages
      fromUuid: 'uuid'
      title: 'text'
      text: 'text'
      isRead: 'boolean'
      data: 'text' # JSON conversationUuid
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['groupUuid', 'uuid']
    withClusteringOrderBy: [['groupUuid', 'desc'], ['uuid', 'desc']]
  }
  {
    name: 'notifications_by_userUuid_and_uniqueId'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      userUuid: 'uuid'
      groupUuid: 'uuid'
      uniqueId: 'text' # used so there's not a bunch of dupe messages
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['uniqueId']
  }
  {
    name: 'notifications_by_roleUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      roleUuid: 'uuid'
      groupUuid: 'uuid'
      uniqueId: 'text' # used so there's not a bunch of dupe messages
      fromUuid: 'uuid'
      title: 'text'
      text: 'text'
      isRead: 'boolean'
      data: 'text' # JSON conversationUuid
    primaryKey:
      partitionKey: ['roleUuid']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
]

class NotificationModel
  SCYLLA_TABLES: tables

  upsert: (notification) =>
    notification = defaultNotification notification

    (if notification.uniqueId
      @getByUserUuidAndUniqueId(
        notification.userUuid, notification.uniqueId
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
      setUser = _.omit notification, ['userUuid', 'groupUuid', 'uuid']
      setRole = _.omit notification, ['roleUuid', 'uuid']
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
        if notification.userUuid
          [
            cknex().update 'notifications_by_userUuid'
            .set setUser
            .where 'userUuid', '=', notification.userUuid
            .andWhere 'groupUuid', '=', notification.groupUuid
            .andWhere 'uuid', '=', notification.uuid
            .usingTTL ttl
            .run()

            cknex().update 'notifications_by_userUuid_and_uniqueId'
            .set _.pick notification, ['uuid' ,'groupUuid']
            .where 'userUuid', '=', notification.userUuid
            .andWhere 'uniqueId', '=', notification.uniqueId
            .usingTTL ttl
            .run()
         ]

        if notification.roleUuid
          cknex().update 'notifications_by_roleUuid'
          .set setRole
          .where 'roleUuid', '=', notification.roleUuid
          .andWhere 'uuid', '=', notification.uuid
          .usingTTL ttl
          .run()
      ]
      .then ->
        notification

  getAllByUserUuid: (userUuid) ->
    cknex().select '*'
    .from 'notifications_by_userUuid'
    .where 'userUuid', '=', userUuid
    .run()
    .map defaultNotificationOutput

  getByUserUuidAndUniqueId: (userUuid, uniqueId) ->
    cknex().select '*'
    .from 'notifications_by_userUuid_and_uniqueId'
    .where 'userUuid', '=', userUuid
    .andWhere 'uniqueId', '=', uniqueId
    .run {isSingle: true}
    .then defaultNotificationOutput

  getAllByUserUuidAndGroupUuid: (userUuid, groupUuid) ->
    cknex().select '*'
    .from 'notifications_by_userUuid'
    .where 'userUuid', '=', userUuid
    .andWhere 'groupUuid', '=', groupUuid
    .run()
    .map defaultNotificationOutput

  getAllByRoleUuid: (roleUuid) ->
    cknex().select '*'
    .from 'notifications_by_roleUuid'
    .where 'roleUuid', '=', roleUuid
    .run()
    .map defaultNotificationOutput

  deleteByNotification: (notification) ->
    Promise.all _.filter _.flatten [
      if notification.userUuid
        [
          cknex().delete()
          .from 'notifications_by_userUuid'
          .where 'userUuid', '=', notification.userUuid
          .andWhere 'groupUuid', '=', notification.groupUuid
          .andWhere 'uuid', '=', notification.uuid
          .run()

          cknex().delete()
          .from 'notifications_by_userUuid_and_uniqueId'
          .where 'userUuid', '=', notification.userUuid
          .andWhere 'uniqueId', '=', notification.uniqueId
          .run()
       ]

      if notification.roleUuid
        cknex().delete()
        .from 'notifications_by_roleUuid'
        .where 'roleUuid', '=', notification.roleUuid
        .andWhere 'uuid', '=', notification.uuid
        .run()
    ]

module.exports = new NotificationModel()
