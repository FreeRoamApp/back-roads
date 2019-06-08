_ = require 'lodash'
uuid = require 'node-uuid'
moment = require 'moment'
crypto = require 'crypto'
base64url = require 'base64url'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

TTL_S = 3600

class LoginLinkModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'login_links'
        keyspace: 'free_roam'
        fields:
          time: {type: 'timestamp', defaultFn: -> new Date()}
          expireTime:
            type: 'timestamp', defaultFn: -> moment().add(TTL_S * 1000).toDate()
          userId: 'uuid'
          data: 'json'
          token: 'text'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['token']
      }
    ]

  create: (loginLink) =>
    @generateLoginToken().then (token) =>
      loginLink = _.assign {token}, loginLink
      @upsert loginLink, {ttl: TTL_S}

  generateLoginToken: ->
    # Token generation follows the 2 factor auth pattern
    # http://tools.ietf.org/html/rfc4226#section-5.3
    Promise.promisify(crypto.randomBytes) 8
    .then (buffer) ->
      base64url buffer.toString('base64')

  getByUserIdAndToken: (userId, token) =>
    cknex().select '*'
    .from 'login_links'
    .where 'userId', '=', userId
    .andWhere 'token', '=', token
    .run {isSingle: true}
    .then @defaultOutput

module.exports = new LoginLinkModel()
