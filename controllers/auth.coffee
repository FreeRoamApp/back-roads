_ = require 'lodash'
router = require 'exoid-router'
bcrypt = require 'bcrypt'
Joi = require 'joi'
Promise = require 'bluebird'
geoip = require 'geoip-lite'
jwt = require 'jsonwebtoken'

Auth = require '../models/auth'
User = require '../models/user'
Connection = require '../models/connection'
GroupCtrl = require './group'
TwitchService = require '../services/connection_twitch'
schemas = require '../schemas'
config = require '../config'

BCRYPT_ROUNDS = 10

class AuthCtrl
  login: ({language}, {headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress
    isServerSide = ip?.indexOf('::ffff:10.') isnt -1
    if isServerSide
      ip = null
      country = null
    else
      country = geoip.lookup(ip)?.country
    User.create {ip, country, language: language?.toLowerCase?()}
    .tap (user) ->
      if language is 'pt'
        # put all portuguese users in bruno's group
        GroupCtrl.joinById {id: config.GROUPS.PLAY_HARD.ID}, {user}
    .then (user) ->
      Auth.fromUserId user.id

  join: ({email, username, password}, {user}) ->
    insecurePassword = password
    username = username?.toLowerCase()

    valid = Joi.validate {password, email, username},
      password: Joi.string().min(6).max(1000)
      email: schemas.user.email
      username: schemas.user.username
    , {presence: 'required'}

    if valid.error
      errorField = valid.error.details[0].path
      info = switch errorField
        when 'username' then 'error.invalidUsername'
        when 'password' then 'error.invalidPassword'
        when 'email' then 'error.invalidEmail'
        else 'error.invalid'
      router.throw {
        status: 400
        info:
          langKey: info
          field: errorField
        ignoreLog: true
      }

    if user and user.password
      router.throw {
        status: 401
        info:
          langKey: 'error.passwordSet'
          field: 'password'
        ignoreLog: true
      }
    else if user
      User.getByUsername username
      .then (existingUser) ->
        if existingUser
          router.throw {
            status: 401
            info:
              langKey: 'error.usernameTaken'
              field: 'username'
            ignoreLog: true
          }

        Promise.promisify(bcrypt.hash)(insecurePassword, BCRYPT_ROUNDS)
        .then (password) ->
          User.updateById user.id, {username, password, email, isMember: true}
      .then ->
        Auth.fromUserId user.id

  loginTwitchExtension: ({token, language}, {user, headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress
    country = geoip.lookup(ip)?.country

    secret = new Buffer config.TWITCH.SECRET_KEY, 'base64'
    decoded = jwt.verify token, secret

    unless decoded.user_id
      router.throw status: 400, info: 'need permissions'

    Connection.getBySiteAndSourceId 'twitch', decoded.user_id
    .then (connection) ->
      if connection
        Auth.fromUserId connection.userId
      else
        Promise.all [
          Connection.upsert {
            site: 'twitch', token: '', userId: user.id
            sourceId: decoded.user_id
            # TODO: store channelId so we can use that token to grab info
          }
          User.updateById user.id, {isMember: true}
        ]
        .then ->
          Auth.fromUserId user.id

  loginTwitch: ({code, idToken}, {user, headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress
    country = geoip.lookup(ip)?.country

    decodedIdToken = jwt.decode idToken
    sourceId = decodedIdToken.sub

    TwitchService.getInfoFromCode code
    .then (info) ->
      Connection.getBySiteAndSourceId 'twitch', sourceId
      .then (connection) ->
        if connection
          Auth.fromUserId connection.userId
        else
          Promise.all [
            Connection.upsert {
              site: 'twitch', token: info.access_token
              userId: user.id, sourceId: sourceId
              data: {refreshToken: info.refresh_token}
            }
            User.updateById user.id, {isMember: true}
          ]
          .then ->
            Auth.fromUserId user.id

  loginUsername: ({username, password}) ->
    insecurePassword = password
    username = username?.toLowerCase()

    valid = Joi.validate {password, username},
      password: Joi.string().min(6).max(1000)
      username: schemas.user.username
    , {presence: 'required'}

    if valid.error
      errorField = valid.error.details[0].path
      langKey = switch errorField
        when 'username' then 'error.invalidUsername'
        when 'password' then 'error.invalidPassword'
        else 'invalid'
      router.throw {
        status: 400
        info:
          langKey: langKey
          field: errorField
        ignoreLog: true
      }

    User.getByUsername username
    .then (user) ->
      if user and user.password
        return Promise.promisify(bcrypt.compare)(
          insecurePassword
          user.password
        )
        .then (success) ->
          if success
            return user
          router.throw {
            status: 401
            info:
              langKey: 'error.incorrectPassword'
              field: 'password'
          }

      # Invalid auth mechanism used
      else if user
        router.throw {
          status: 401
          info:
            langKey: 'error.incorrectPassword'
            field: 'password'
        }

      # don't create user for just username login
      else
        router.throw {
          status: 401
          info:
            langKey: 'error.usernameNotFound'
            field: 'username'
        }

    .then (user) ->
      Auth.fromUserId user.id


module.exports = new AuthCtrl()
