_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

TWO_DAYS_SECONDS = 3600 * 24 * 2

scyllaFields =
  userId: 'uuid'
  token: 'text'
  deviceId: 'text'
  sourceType: 'text'
  isActive: {type: 'boolean', defaultFn: -> true}
  time: {type: 'timestamp', defaultFn: -> new Date()}
  errorCount: {type: 'int', defaultFn: -> 0}

class PushToken extends Base
  getScyllaTables: ->
    [
      {
        name: 'push_tokens_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['token']
      }
      {
        name: 'push_tokens_by_token'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['token']
          clusteringColumns: ['userId']
      }
    ]

  upsert: (token) =>
    console.log 'upsert token', token
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

  sanitizePublic: (token) ->
    _.pick token, [
      'userId'
      'token'
      'sourceType'
    ]


module.exports = new PushToken()
