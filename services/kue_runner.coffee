_ = require 'lodash'
kue = require 'kue'

KueService = require './kue'
KueCreateService = require './kue_create'
PlacesService = require './places'
config = require '../config'

TYPES =
  "#{KueCreateService.JOB_TYPES.DAILY_UPDATE_PLACE}":
    {fn: PlacesService.updateDailyInfo, concurrencyPerCpu: 1}

class KueRunnerService
  listen: ->
    console.log 'listening to kue'
    _.forEach TYPES, ({fn, concurrencyPerCpu}, type) ->
      KueService.process type, concurrencyPerCpu, (job, ctx, done) ->
        # KueCreateService.setCtx type, ctx
        try
          fn job.data
          .then (response) ->
            done null, response
          .catch (err) ->
            console.log 'kue err', type
            done err
        catch err
          done err

module.exports = new KueRunnerService()
