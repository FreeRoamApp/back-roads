_ = require 'lodash'
router = require 'exoid-router'
bcrypt = require 'bcrypt-nodejs'
Joi = require 'joi'
Promise = require 'bluebird'
geoip = require 'geoip-lite'
jwt = require 'jsonwebtoken'

Auth = require '../models/auth'
Subscription = require '../models/subscription'
User = require '../models/user'
config = require '../config'

class AuthCtrl
  # create new user account if it doesn't exist
  login: ({language}, {headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress
    isServerSide = ip?.indexOf('::ffff:10.') isnt -1
    if isServerSide
      ip = null
      country = null
    else
      country = geoip.lookup(ip)?.country

    User.upsert {language: language?.toLowerCase?()}
    .then (user) ->
      # subscribe to base topics
      # (so when they use another device, it grabs all the required ones)
      # don't need to block for this
      Subscription.subscribeInitial user
      Auth.fromUserId user.id

  join: ({email, username, password}, {user}) ->
    insecurePassword = password
    username = username?.toLowerCase()

    valid = Joi.validate {password, email, username},
      password: Joi.string().min(6).max(1000)
      email: Joi.string().email().allow('')
      username: Joi.string().min(1).max(100).allow(null).regex /^[a-zA-Z0-9-_]+$/
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

        Promise.promisify(bcrypt.hash)(insecurePassword, bcrypt.genSaltSync(config.BCRYPT_ROUNDS), null)
        .then (password) ->
          User.updateByUser user, {username, password, email}
      .then ->
        Auth.fromUserId user.id

  loginUsername: ({username, password}) ->
    insecurePassword = password
    username = username?.toLowerCase()

    valid = Joi.validate {password, username},
      password: Joi.string().min(6).max(1000)
      username: Joi.string().min(1).max(100).allow(null).regex /^[a-zA-Z0-9-_]+$/
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
