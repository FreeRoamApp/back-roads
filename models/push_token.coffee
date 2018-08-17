_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

TWO_DAYS_SECONDS = 3600 * 24 * 2

tables = [
  {
    name: 'push_tokens_by_userUuid'
    keyspace: 'free_roam'
    fields:
      userUuid: 'uuid'
      token: 'text'
      sourceType: 'text'
      isActive: 'boolean'
      errorCount: 'int'
    primaryKey:
      partitionKey: ['userUuid']
      clusteringColumns: ['token']
  }
  {
    name: 'push_tokens_by_token'
    keyspace: 'free_roam'
    fields:
      userUuid: 'uuid'
      token: 'text'
      deviceId: 'text'
      sourceType: 'text'
      isActive: 'boolean'
      errorCount: 'int'
    primaryKey:
      partitionKey: ['token']
      clusteringColumns: ['userUuid']
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
    userUuid: null
    errorCount: 0
  }

defaultTokenOutput = (token) ->
  unless token?
    return null

  token.userUuid = "#{token.userUuid}"

  _.defaults token, {
    sourceType: null
    token: null
    deviceId: null
    isActive: true
    userUuid: null
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

    qByUserUuid = cknex().update 'push_tokens_by_userUuid'
    .set _.omit token, ['userUuid', 'token']
    .where 'userUuid', '=', token.userUuid
    .andWhere 'token', '=', token.token

    qByToken = cknex().update 'push_tokens_by_token'
    .set _.omit token, ['token', 'userUuid']
    .where 'token', '=', token.token
    .andWhere 'userUuid', '=', token.userUuid

    unless token.isActive
      qByUserUuid.usingTTL TWO_DAYS_SECONDS
      qByToken.usingTTL TWO_DAYS_SECONDS

    Promise.all [
      qByUserUuid.run()
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

  getAllByUserUuid: (userUuid) ->
    cknex().select '*'
    .from 'push_tokens_by_userUuid'
    .where 'userUuid', '=', userUuid
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
      .from 'push_tokens_by_userUuid'
      .where 'token', '=', pushToken.token
      .andWhere 'userUuid', '=', pushToken.userUuid
      .run()

      cknex().delete()
      .from 'push_tokens_by_token'
      .where 'token', '=', pushToken.token
      .andWhere 'userUuid', '=', pushToken.userUuid
      .run()
    ]

  sanitizePublic: (token) ->
    _.pick token, [
      'userUuid'
      'token'
      'sourceType'
    ]


module.exports = new PushToken()
