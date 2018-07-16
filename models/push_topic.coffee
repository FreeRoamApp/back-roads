_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

# topics are NOT secure. anyone can subscribe. for secure messaging, always
# use the devicePushTopic. for private channels, use devicePushTopic


tables = [
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

defaultPushTopic = (pushTopic) ->
  unless pushTopic?
    return null

  _.defaults pushTopic, {
    sourceType: 'all'
    sourceId: 'all'
    lastUpdateTime: new Date()
  }

defaultPushTopicOutput = (pushTopic) ->
  unless pushTopic?
    return null

  pushTopic.groupId = "#{pushTopic.groupId}"
  pushTopic

class PushTopic
  SCYLLA_TABLES: tables

  upsert: (pushTopic) ->
    # TODO: more elegant solution to stripping what lodash adds w/ _.defaults
    delete pushTopic.get
    delete pushTopic.values
    delete pushTopic.keys
    delete pushTopic.forEach

    pushTopic = defaultPushTopic pushTopic

    Promise.all [
      cknex().update 'push_topics_by_userId'
      .set _.omit pushTopic, [
        'userId', 'token', 'groupId', 'sourceType', 'sourceId'
      ]
      .where 'userId', '=', pushTopic.userId
      .andWhere 'token', '=', pushTopic.token
      .andWhere 'groupId', '=', pushTopic.groupId
      .andWhere 'sourceType', '=', pushTopic.sourceType
      .andWhere 'sourceId', '=', pushTopic.sourceId
      .run()
    ]
    .then ->
      pushTopic

  getAllByUserId: (userId) ->
    cknex().select '*'
    .from 'push_topics_by_userId'
    .where 'userId', '=', userId
    .run()
    .map defaultPushTopicOutput

  getAllByUserIdAndToken: (userId, token) ->
    cknex().select '*'
    .from 'push_topics_by_userId'
    .where 'userId', '=', userId
    .andWhere 'token', '=', token
    .run()
    .map defaultPushTopicOutput

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

module.exports = new PushTopic()
