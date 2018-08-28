_ = require 'lodash'

CacheService = require '../services/cache'
cknex = require '../services/cknex'
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
      email: 'text'
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
      email: 'text'
      name: 'text'
      avatarImage: 'text'
      language: 'text'
      flags: 'text'
    primaryKey:
      partitionKey: ['username']
  }
  {
    name: 'users_by_email'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      username: 'text'
      password: 'text'
      email: 'text'
      name: 'text'
      avatarImage: 'text'
      language: 'text'
      flags: 'text'
    primaryKey:
      partitionKey: ['email']
  }
]

defaultUser = (user) ->
  unless user?
    return null

  user.flags = JSON.stringify user.flags

  # hacky https://github.com/datastax/nodejs-driver/pull/243
  delete user.get
  delete user.values
  delete user.keys
  delete user.forEach

  _.defaults user, {
    id: cknex.getTimeUuid()
    language: 'en'
  }

defaultUserOutput = (user) ->
  unless user?
    return null

  if user.flags
    user.flags = try
      JSON.parse user.flags
    catch
      {}
  else
    user.flags = {}

  user = _.defaults user, {
    id: "#{user.id}"
    username: null
    language: 'en'
  }

class UserModel
  SCYLLA_TABLES: tables

  getById: (id) ->
    cknex().select '*'
    .from 'users_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultUserOutput

  getByUsername: (username) ->
    cknex().select '*'
    .from 'users_by_username'
    .where 'username', '=', username
    .run {isSingle: true}
    .then defaultUserOutput

  getAllByUsername: (username, {limit} = {}) ->
    null # TODO: search using >= operator on username?

  upsert: (user) ->
    user = defaultUser user

    Promise.all _.filter [
      cknex().update 'users_by_id'
      .set _.omit user, ['id']
      .where 'id', '=', user.id
      .run()

      if user.username
        cknex().update 'users_by_username'
        .set _.omit user, ['username']
        .where 'username', '=', user.username
        .run()

      if user.email
        cknex().update 'users_by_email'
        .set _.omit user, ['email']
        .where 'email', '=', user.email
        .run()
    ]
    .then ->
      defaultUserOutput user

  updateByUser: (user, newUser) ->
    newUser = _.defaults newUser, user
    newUser = defaultUser newUser

    username = user.username or newUser.username
    email = user.email or newUser.email

    Promise.all _.filter [
      cknex().update 'users_by_id'
      .set _.omit newUser, ['id']
      .where 'id', '=', user.id
      .run()

      if username
        cknex().update 'users_by_username'
        .set _.omit newUser, ['username']
        .where 'username', '=', username
        .run()

      if email
        cknex().update 'users_by_email'
        .set _.omit newUser, ['email']
        .where 'email', '=', email
        .run()
    ]
    .then ->
      defaultUserOutput user

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
