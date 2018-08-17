log = require 'loga'

Auth = require '../models/auth'
User = require '../models/user'
config = require '../config'

class AuthService
  middleware: (req, res, next) =>
    # set req.user if authed
    accessToken = req.query?.accessToken
    userAgent = req.headers?['user-agent'] or req.query?.userAgent

    unless accessToken?
      return next()


    Auth.userUuidFromAccessToken accessToken
    .then User.getByUuid, {preferCache: true}
    .then (user) ->
      if not user?
        next()
      else
        # Authentication successful
        req.user = user
        next()
    .catch (err) ->
      log.warn err
      next()

  exoidMiddleware: ({accessToken, userAgent}, req) =>
    if accessToken
      Auth.userUuidFromAccessToken accessToken
      .then User.getByUuid, {preferCache: true}
      .then (user) ->
        if user
          req.user = user
        req
      .catch ->
        req

    else
      Promise.resolve req

  getAppKeyFromUserAgent: (userAgent) ->
    unless userAgent
      return 'freeroam'
    regex = new RegExp '(freeroam)\/([a-zA-Z0-9]+/)?([0-9\.]+)'
    matches = userAgent.match(regex)
    appKey = matches?[2]?.replace('/', '') or 'freeroam'
    appKey


module.exports = new AuthService()
