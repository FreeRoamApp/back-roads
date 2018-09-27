_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

User = require '../models/user'
config = require '../config'

HEALTHCHECK_TIMEOUT = 20000
HEALTHCHECK_THROW_TIMEOUT = 40000
AUSTIN_USERNAME = 'austin'


class HealthCtrl
  check: (req, res, next) =>
    @getStatus()
    .then (status) ->
      res.json status
    .catch next

  # used for readinessProbe
  checkThrow: (req, res, next) =>
    @getStatus {timeout: HEALTHCHECK_THROW_TIMEOUT}
    .then (status) ->
      if status.healthy
        res.send 'ok'
      else
        res.status(400).send 'fail'

  getStatus: ({timeout} = {}) ->
    timeout ?= HEALTHCHECK_TIMEOUT
    Promise.all [
      User.getByUsername AUSTIN_USERNAME
      .timeout timeout
      .catch -> null

    ]
    .then (responses) ->
      [user] = responses
      result =
        users: user?.username is AUSTIN_USERNAME

      result.healthy = _.every _.values result
      return result

module.exports = new HealthCtrl()
