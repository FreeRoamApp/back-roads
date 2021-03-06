_ = require 'lodash'
md5 = require 'md5'

Base = require './base'
CacheService = require '../services/cache'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
config = require '../config'

REFERRER_TTL_S = 3600 * 24 * 31 # 1 month

scyllaFields =
  id: 'timeuuid'
  username: 'text'
  password: 'text'
  email: 'text'
  name: 'text'
  avatarImage: 'json'
  language: {type: 'text', defaultFn: -> 'en'}
  flags: 'json'
  links: {type: 'map', subType: 'text', subType2: 'text'}

class UserModel extends Base
  getScyllaTables: ->
    [
      # TODO: separate table for last_session_by_userId: lastActiveTime, lastActiveIp
      {
        name: 'users_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
      {
        name: 'users_by_username'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['username']
      }
      {
        name: 'users_by_email'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['email']
      }

      # referrals / referrers
      {
        name: 'user_referrers_by_userId'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          userId: 'timeuuid'
          referrerUserId: 'timeuuid'
        primaryKey:
          partitionKey: ['userId']
      }
      {
        name: 'user_referrers_by_referrerUserId'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          userId: 'timeuuid'
          referrerUserId: 'timeuuid'
        primaryKey:
          partitionKey: ['referrerUserId']
          clusteringColumns: ['userId']
      }
    ]

  getElasticSearchIndices: ->
    [
      {
        name: 'users'
        mappings:
          username: {type: 'text'}
          name: {type: 'text'}
          avatarImage: {type: 'text'}
      }
    ]

  getById: (id) =>
    cknex().select '*'
    .from 'users_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getByUsername: (username) =>
    cknex().select '*'
    .from 'users_by_username'
    .where 'username', '=', username
    .run {isSingle: true}
    .then @defaultOutput

  getByEmail: (email) =>
    cknex().select '*'
    .from 'users_by_email'
    .where 'email', '=', email
    .run {isSingle: true}
    .then @defaultOutput

  getAllByUsername: (username, {limit} = {}) ->
    null # TODO: search using >= operator on username?

  getEmailVerificationLinkByIdAndEmail: (id, email) ->
    token = md5 "#{config.EMAIL_VERIFY_SALT}#{id}#{email}"
    "https://#{config.FREE_ROAM_HOST}/verify-email/#{id}/#{token}"

  getEmailUnsubscribeLinkByUser: ({id, email}) ->
    token = md5 "#{config.EMAIL_VERIFY_SALT}#{id}#{email}"
    "https://freeroam.app/unsubscribe-email/#{id}/#{token}"

  setReferrer: (userId, referrerUserId) =>
    console.log 'set referrer', userId, referrerUserId
    @getReferrerUserIdByUserId userId
    .then (oldReferrerUserId) ->
      if oldReferrerUserId
        cknex().delete()
        .from 'user_referrers_by_referrerUserId'
        .where 'referrerUserId', '=', oldReferrerUserId
        .andWhere 'userId', '=', userId
        .run()
    .then ->
      Promise.all [
        cknex().update 'user_referrers_by_userId'
        .set {referrerUserId}
        .where 'userId', '=', userId
        .usingTTL REFERRER_TTL_S
        .run()

        cknex().insert {userId, referrerUserId}
        .into 'user_referrers_by_referrerUserId'
        .usingTTL REFERRER_TTL_S
        .run()
      ]

  getReferrerUserIdByUserId: (userId) ->
    cknex().select '*'
    .from 'user_referrers_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}
    .then (referrer) ->
      referrer?.referrerUserId

  getUniqueUsername: (baseUsername, appendedNumber = 0) =>
    username = "#{baseUsername}".toLowerCase()
    username = if appendedNumber \
               then "#{username}#{appendedNumber}"
               else username
    @getByUsername username
    .then (existingUser) =>
      if appendedNumber > MAX_UNIQUE_USERNAME_ATTEMPTS
        null
      else if existingUser
        @getUniqueUsername baseUsername, appendedNumber + 1
      else
        username

  getDisplayName: (user) ->
    user?.username or user?.name or 'anonymous'

  search: ({query, sort, limit}) =>
    limit ?= 50

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      body:
        query:
          # random ordering so they don't clump on map
          function_score:
            query: query
            boost_mode: 'replace'
        sort: sort
        from: 0
        # it'd be nice to have these distributed more evently
        # grab ~2,000 and get random 250?
        # is this fast/efficient enough?
        size: limit
    }
    .then ({hits}) =>
      total = hits.total
      {
        total: total
        users: _.map hits.hits, ({_id, _source}) =>
          @defaultESOutput _.defaults _source, {id: _id}
      }

  defaultESInput: (user) ->
    user = super user
    if typeof user.avatarImage is 'object'
      user.avatarImage = JSON.stringify user.avatarImage
    user

  defaultESOutput: (user) ->
    if user.avatarImage
      user.avatarImage = try
        JSON.parse user.avatarImage
      catch
        {}
    else
      user.avatarImage = {}

    user

  sanitizePrivate: _.curry (requesterId, user) ->
    unless user
      return null
    _.omit user, ['password']

  sanitizePublic: _.curry (requesterId, user) ->
    unless user
      return null
    sanitizedUser = _.pick user, [
      'id'
      'username'
      'name'
      'data'
      'karma'
      'avatarImage'
      'links'
      'embedded'
    ]
    sanitizedUser.flags = _.pick user.flags, [
      'isModerator', 'isDev', 'isChatBanned', 'isSupporter'
    ]
    sanitizedUser

module.exports = new UserModel()
