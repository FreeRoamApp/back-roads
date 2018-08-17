_ = require 'lodash'

CacheService = require '../services/cache'
cknex = require '../services/cknex'
config = require '../config'

tables = [
  # TODO: separate table for last_session_by_userUuid: lastActiveTime, lastActiveIp
  {
    name: 'users_by_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      username: 'text'
      password: 'text'
      email: 'text'
      name: 'text'
      avatarImage: 'text'
      language: 'text'
      flags: 'text'
    primaryKey:
      partitionKey: ['uuid']
  }
  {
    name: 'users_by_username'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
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
      uuid: 'timeuuid'
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

  _.defaults user, {
    uuid: cknex.getTimeUuid()
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
    uuid: "#{user.uuid}"
    username: null
    language: 'en'
  }

class UserModel
  SCYLLA_TABLES: tables

  getByUuid: (uuid) ->
    cknex().select '*'
    .from 'users_by_uuid'
    .where 'uuid', '=', uuid
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
      cknex().update 'users_by_uuid'
      .set _.omit user, ['uuid']
      .where 'uuid', '=', user.uuid
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
    newUser = defaultUser newUser

    Promise.all _.filter [
      cknex().update 'users_by_uuid'
      .set _.omit newUser, ['uuid']
      .where 'uuid', '=', user.uuid
      .run()

      if user.username
        cknex().update 'users_by_username'
        .set _.omit newUser, ['username']
        .where 'username', '=', user.username
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
      'uuid'
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
