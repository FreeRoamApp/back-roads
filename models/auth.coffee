_ = require 'lodash'
Promise = require 'bluebird'
jwt = require 'jsonwebtoken'

config = require '../config'

generateAccessToken = (userId) ->
  jwt.sign {
    userId: userId
    scopes: ['*']
  }, config.JWT_ES256_PRIVATE_KEY, {
    algorithm: 'ES256'
    issuer: config.JWT_ISSUER
    subject: userId
  }

decodeAccessToken = (token) ->
  Promise.promisify(jwt.verify, jwt)(
    token,
    config.JWT_ES256_PUBLIC_KEY,
    {issuer: config.JWT_ISSUER}
  )

class AuthModel
  fromUserId: (userId) ->
    {accessToken: generateAccessToken(userId)}

  userIdFromAccessToken: (token) ->
    decodeAccessToken(token)
    .then ({userId} = {}) -> userId

module.exports = new AuthModel()
