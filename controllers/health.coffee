_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

User = require '../models/user'
config = require '../config'

HEALTHCHECK_TIMEOUT = 20000
AUSTIN_USERNAME = 'austin'


class HealthCtrl
  check: (req, res, next) ->
    Promise.all [
      User.getByUsername AUSTIN_USERNAME
      .timeout HEALTHCHECK_TIMEOUT
      .catch -> null

    ]
    .then (responses) ->
      [user] = responses
      result =
        users: user?.username is AUSTIN_USERNAME

      result.healthy = _.every _.values result
      return result
    .then (status) ->
      res.json status
    .catch next

module.exports = new HealthCtrl()
