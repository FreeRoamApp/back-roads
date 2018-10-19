_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

# topics are NOT secure. anyone can subscribe. for secure messaging, always
# use the devicePushTopic. for private channels, use devicePushTopic

class PushTopic extends Base
  SCYLLA_TABLES: [
    {
      name: 'push_topics_by_userId'
      keyspace: 'free_roam'
      fields:
        userId: 'uuid'
        groupId: 'uuid' # config.EMPTY_UUID for all
        sourceType: 'text' # conversation, video, thread, etc...
        sourceId: 'text' # id or 'all'
        token: 'text'
        deviceId: 'text'
        lastUpdateTime: 'timestamp'
      primaryKey:
        partitionKey: ['userId']
        clusteringColumns: [
          'token', 'groupId', 'sourceType', 'sourceId'
        ]
    }
  ]

  getAllByUserId: (userId) =>
    cknex().select '*'
    .from 'push_topics_by_userId'
    .where 'userId', '=', userId
    .run()
    .map @defaultOutput

  getAllByUserIdAndToken: (userId, token) =>
    cknex().select '*'
    .from 'push_topics_by_userId'
    .where 'userId', '=', userId
    .andWhere 'token', '=', token
    .run()
    .map @defaultOutput

  # TODO: super() (deleteByRow)
  deleteByPushTopic: (pushTopic) ->
    cknex().delete()
    .from 'push_topics_by_userId'
    .where 'userId', '=', pushTopic.userId
    .andWhere 'token', '=', pushTopic.token
    .andWhere 'groupId', '=', pushTopic.groupId
    .andWhere 'sourceType', '=', pushTopic.sourceType
    .andWhere 'sourceId', '=', pushTopic.sourceId
    .run()

  deleteByPushToken: (pushToken) ->
    cknex().delete()
    .from 'push_topics_by_userId'
    .where 'userId', '=', pushToken.userId
    .andWhere 'token', '=', pushToken.token
    .run()

  defaultInput: (pushTopic) ->
    unless pushTopic?
      return null

    _.defaults pushTopic, {
      sourceType: 'all'
      sourceId: 'all'
      lastUpdateTime: new Date()
    }

  defaultOutput: (pushTopic) ->
    unless pushTopic?
      return null

    pushTopic.groupId = "#{pushTopic.groupId}"
    pushTopic.userId = "#{pushTopic.userId}"
    pushTopic

module.exports = new PushTopic()
