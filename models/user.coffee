_ = require 'lodash'
uuid = require 'node-uuid'
PcgRandom = require 'pcg-random'

r = require '../services/rethinkdb'
CacheService = require '../services/cache'
config = require '../config'

tables = [
  # TODO: separate table for last_session_by_userId: lastActiveTime, lastActiveIp
  {
    name: 'users_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      username: 'text'
      password: 'text'
      name: 'text'
      avatarImage: 'text'
      language: 'text'
      flags: 'text'
    primaryKey:
      partitionKey: ['id']
  }
  {
    name: 'users_by_username'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      username: 'text'
      password: 'text'
      name: 'text'
      avatarImage: 'text'
      language: 'text'
      flags: 'text'
    primaryKey:
      partitionKey: ['username']
  }
]

defaultUser = (user) ->
  unless user?
    return null

  _.defaults user, {
    id: uuid.v4()
    username: null
    data: {}
  }

defaultUserOutput = (user) ->
  unless user?
    return null

  _.defaults user, {
    id: uuid.v4()
    username: null
    data: {}
  }

class UserModel
  SCYLLA_TABLES: tables

  getById: (id) ->
    cknex().select '*'
    .from 'users_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultTokenOutput

  getByUsername: (username) ->
    cknex().select '*'
    .from 'users_by_username'
    .where 'username', '=', username
    .run {isSingle: true}
    .then defaultTokenOutput

  getAllByUsername: (username, {limit} = {}) ->
    null # TODO: search using >= operator on username?

  upsert: (id, user) ->
    token = defaultToken token

    Promise.all [
      cknex().update 'users_by_id'
      .set _.omit user, ['id']
      .where 'id', '=', groupPage.id
      .run()

      cknex().update 'users_by_username'
      .set _.omit user, ['username']
      .where 'username', '=', groupPage.username
      .run()
    ]

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

  sanitizePublic: _.curry (requesterId, user) ->
    unless user
      return null
    sanitizedUser = _.pick user, [
      'id'
      'username'
      'name'
      'avatarImage'
      'embedded'
    ]
    sanitizedUser.flags = _.pick user.flags, [
      'isModerator', 'isDev', 'isChatBanned'
    ]
    sanitizedUser

module.exports = new UserModel()
