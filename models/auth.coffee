_ = require 'lodash'
Promise = require 'bluebird'
jwt = require 'jsonwebtoken'

config = require '../config'

generateAccessToken = (userUuid) ->
  jwt.sign {
    userUuid: userUuid
    scopes: ['*']
  }, config.JWT_ES256_PRIVATE_KEY, {
    algorithm: 'ES256'
    issuer: config.JWT_ISSUER
    subject: userUuid
  }

decodeAccessToken = (token) ->
  Promise.promisify(jwt.verify, jwt)(
    token,
    config.JWT_ES256_PUBLIC_KEY,
    {issuer: config.JWT_ISSUER}
  )

class AuthModel
  fromUserUuid: (userUuid) ->
    {accessToken: generateAccessToken(userUuid)}

  userUuidFromAccessToken: (token) ->
    decodeAccessToken(token)
    .then ({userUuid} = {}) ->
      userUuid

module.exports = new AuthModel()
