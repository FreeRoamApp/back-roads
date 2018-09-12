_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

TWO_DAYS_SECONDS = 3600 * 24 * 2

class PushToken extends Base
  SCYLLA_TABLES: [
    {
      name: 'push_tokens_by_userId'
      keyspace: 'free_roam'
      fields:
        userId: 'uuid'
        token: 'text'
        deviceId: 'text'
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

  upsert: (token) =>
    if token.isActive
      ttl = null
    else
      ttl = TWO_DAYS_SECONDS

    super token, {ttl}

  getByToken: (token) =>
    cknex().select '*'
    .from 'push_tokens_by_token'
    .where 'token', '=', token
    .run {isSingle: true}
    .then @defaultOutput

  getAllByUserId: (userId) =>
    cknex().select '*'
    .from 'push_tokens_by_userId'
    .where 'userId', '=', userId
    .run()
    .map @defaultOutput

  getAllByToken: (token) =>
    cknex().select '*'
    .from 'push_tokens_by_token'
    .where 'token', '=', token
    .run()
    .map @defaultOutput

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

  defaultInput: (token) ->
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

  defaultOutput: (token) ->
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


  sanitizePublic: (token) ->
    _.pick token, [
      'userId'
      'token'
      'sourceType'
    ]


module.exports = new PushToken()
