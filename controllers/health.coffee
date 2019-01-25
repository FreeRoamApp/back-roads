_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

User = require '../models/user'
RoutingService = require '../services/routing'
CellSignalService = require '../services/cell_signal'
config = require '../config'

HEALTHCHECK_TIMEOUT = 40000
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
    @getStatusReady {timeout: HEALTHCHECK_THROW_TIMEOUT}
    .then (status) ->
      if status.healthy
        res.send 'ok'
      else
        res.status(400).send 'fail'

  getStatusReady: ({timeout} = {}) ->
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

  # kind of extreme, don't run super-often
  getStatus: ({timeout} = {}) ->
    timeout ?= HEALTHCHECK_TIMEOUT
    Promise.all [
      User.getByUsername AUSTIN_USERNAME
      .timeout timeout
      .catch -> null

      RoutingService.getRoute {
        locations: [
          # den -> arvada
          {lat: 39.7392, lon: -104.9903}
          {lat: 39.8028, lon: -105.0875}
        ]
      }, {preferCache: false}
      .timeout timeout
      .catch (err) -> null

      CellSignalService.getEstimatesByLocation {
        lat: 39.7392, lon: -104.9903 # denver
      }
      .timeout timeout
      .catch (err) -> null

      RoutingService.getDistance(
          # den -> arvada
        {lat: 39.7392, lon: -104.9903}
        {lat: 39.8028, lon: -105.0875}
      )
      .timeout timeout
      .catch (err) -> null
    ]
    .then (responses) ->
      [user, route, cellSignal, distance] = responses
      console.log cellSignal
      result =
        users: user?.username is AUSTIN_USERNAME
        getRoute: route?.time > 1000
        estimateCellSignal: cellSignal?.verizon_lte is 3
        distance: distance?.distance > 5

      result.healthy = _.every _.values result
      return result

module.exports = new HealthCtrl()
