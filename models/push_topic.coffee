_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

# topics are NOT secure. anyone can subscribe. for secure messaging, always
# use the devicePushTopic. for private channels, use devicePushTopic


tables = [
  {
    name: 'push_topics_by_userUuid'
    keyspace: 'free_roam'
    fields:
      userUuid: 'uuid'
      groupUuid: 'uuid' # config.EMPTY_UUID for all
      sourceType: 'text' # conversation, video, thread, etc...
      sourceId: 'text' # id or 'all'
      token: 'text'
      deviceId: 'text'
      lastUpdateTime: 'timestamp'
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: [
        'token', 'groupUuid', 'sourceType', 'sourceId'
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

  pushTopic.groupUuid = "#{pushTopic.groupUuid}"
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
      cknex().update 'push_topics_by_userUuid'
      .set _.omit pushTopic, [
        'userUuid', 'token', 'groupUuid', 'sourceType', 'sourceId'
      ]
      .where 'userUuid', '=', pushTopic.userUuid
      .andWhere 'token', '=', pushTopic.token
      .andWhere 'groupUuid', '=', pushTopic.groupUuid
      .andWhere 'sourceType', '=', pushTopic.sourceType
      .andWhere 'sourceId', '=', pushTopic.sourceId
      .run()
    ]
    .then ->
      pushTopic

  getAllByUserUuid: (userUuid) ->
    cknex().select '*'
    .from 'push_topics_by_userUuid'
    .where 'userUuid', '=', userUuid
    .run()
    .map defaultPushTopicOutput

  getAllByUserUuidAndToken: (userUuid, token) ->
    cknex().select '*'
    .from 'push_topics_by_userUuid'
    .where 'userUuid', '=', userUuid
    .andWhere 'token', '=', token
    .run()
    .map defaultPushTopicOutput

  deleteByPushTopic: (pushTopic) ->
    cknex().delete()
    .from 'push_topics_by_userUuid'
    .where 'userUuid', '=', pushTopic.userUuid
    .andWhere 'token', '=', pushTopic.token
    .andWhere 'groupUuid', '=', pushTopic.groupUuid
    .andWhere 'sourceType', '=', pushTopic.sourceType
    .andWhere 'sourceId', '=', pushTopic.sourceId
    .run()

  deleteByPushToken: (pushToken) ->
    cknex().delete()
    .from 'push_topics_by_userUuid'
    .where 'userUuid', '=', pushToken.userUuid
    .andWhere 'token', '=', pushToken.token
    .run()

module.exports = new PushTopic()
