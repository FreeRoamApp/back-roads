_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

TWO_DAYS_SECONDS = 3600 * 24 * 2

tables = [
  {
    name: 'push_tokens_by_userId'
    keyspace: 'free_roam'
    fields:
      userId: 'uuid'
      token: 'text'
      sourceType: 'text'
      isActive: 'boolean'
      errorCount: 'int'
    primaryKey:
      partitionKey: ['userId']
      clusteringColumns: ['token']
  }
  {
    name: 'push_tokens_by_token'
    keyspace: 'free_roam'
    fields:
      userId: 'uuid'
      token: 'text'
      deviceId: 'text'
      sourceType: 'text'
      isActive: 'boolean'
      errorCount: 'int'
    primaryKey:
      partitionKey: ['token']
      clusteringColumns: ['userId']
  }
]

defaultToken = (token) ->
  unless token?
    return null

  _.defaults token, {
    sourceType: null
    token: null
    deviceId: null
    isActive: true
    userId: null
    errorCount: 0
  }

defaultTokenOutput = (token) ->
  unless token?
    return null

  token.userId = "#{token.userId}"

  _.defaults token, {
    sourceType: null
    token: null
    deviceId: null
    isActive: true
    userId: null
    errorCount: 0
  }

class PushToken
  SCYLLA_TABLES: tables

  upsert: (token) ->
    # TODO: more elegant solution to stripping what lodash adds w/ _.defaults
    delete token.get
    delete token.values
    delete token.keys
    delete token.forEach

    token = defaultToken token

    qByUserId = cknex().update 'push_tokens_by_userId'
    .set _.omit token, ['userId', 'token']
    .where 'userId', '=', token.userId
    .andWhere 'token', '=', token.token

    qByToken = cknex().update 'push_tokens_by_token'
    .set _.omit token, ['token', 'userId']
    .where 'token', '=', token.token
    .andWhere 'userId', '=', token.userId

    unless token.isActive
      qByUserId.usingTTL TWO_DAYS_SECONDS
      qByToken.usingTTL TWO_DAYS_SECONDS

    Promise.all [
      qByUserId.run()
      qByToken.run()
    ]
    .then ->
      token

  getByToken: (token) ->
    cknex().select '*'
    .from 'push_tokens_by_token'
    .where 'token', '=', token
    .run {isSingle: true}
    .then defaultTokenOutput

  getAllByUserId: (userId) ->
    cknex().select '*'
    .from 'push_tokens_by_userId'
    .where 'userId', '=', userId
    .run()
    .map defaultTokenOutput

  getAllByToken: (token) ->
    cknex().select '*'
    .from 'push_tokens_by_token'
    .where 'token', '=', token
    .run()
    .map defaultTokenOutput

  deleteByPushToken: (pushToken) ->
    Promise.all [
      cknex().delete()
      .from 'push_tokens_by_userId'
      .where 'token', '=', pushToken.token
      .andWhere 'userId', '=', pushToken.userId
      .run()

      cknex().delete()
      .from 'push_tokens_by_token'
      .where 'token', '=', pushToken.token
      .andWhere 'userId', '=', pushToken.userId
      .run()
    ]

  sanitizePublic: (token) ->
    _.pick token, [
      'userId'
      'token'
      'sourceType'
    ]


module.exports = new PushToken()
