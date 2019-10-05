_ = require 'lodash'

jobQueues = require './job_queues'
JobCreateService = require './job_create'
EmailService = require './email'
PlacesService = require './places'
config = require '../config'

class JobRunnerService
  constructor: ->
    @queues = {
      SES:
        types:
          "#{JobCreateService.JOB_TYPES.SES.SEND_EMAIL}":
            {fn: EmailService.sendEmail, concurrencyPerCpu: 1}
        queue: jobQueues.SES
      DEFAULT:
        types:
          "#{JobCreateService.JOB_TYPES.DEFAULT.DAILY_UPDATE_PLACE}":
            {fn: PlacesService.updateDailyInfo, concurrencyPerCpu: 1}
        queue: jobQueues.DEFAULT
    }

  listen: ->
    _.forEach @queues, ({types, queue}) ->
      _.forEach types, ({fn, concurrencyPerCpu}, type) ->
        queue.process type, concurrencyPerCpu, (job) ->
          try
            fn job.data
            .catch (err) ->
              console.log 'queue err', err
              throw err
          catch err
            console.log 'queue err', err
            throw err

module.exports = new JobRunnerService()
