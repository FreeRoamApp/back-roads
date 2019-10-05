_ = require 'lodash'
Promise = require 'bluebird'

queues = require './job_queues'
config = require '../config'

DEFAULT_PRIORITY = 0
DEFAULT_TTL_MS = 60 * 1000 * 9 # 9 minutes

JOB_TYPES =
  DEFAULT:
    DAILY_UPDATE_PLACE: 'free_roam:default:daily_update_place'
  SES:
    SEND_EMAIL: 'free_roam:ses:send_email'


class JobCreateService
  JOB_TYPES: JOB_TYPES
  PRIORITIES:
    # lower (1) is higher priority
    normal: 100

  clean: ({types, minStuckTimeMs} = {}) ->
    types ?= ['failed', 'complete', 'wait', 'active']
    Promise.map types, (type) ->
      new Promise (resolve, reject) ->
        jobQueue.clean 5000, type

  # if we need a "synchronous" process across all instances
  # ie. run each job one at a time, we can use something like
  # https://github.com/deugene/oraq
  # see https://github.com/OptimalBits/bull/issues/457
  createJob: (options) =>
    {queueKey, job, priority, ttlMs, delayMs, type,
      maxAttempts, backoff, waitForCompletion} = options

    queueKey ?= 'DEFAULT'

    unless type? and _.includes _.values(JOB_TYPES[queueKey]), type
      throw new Error 'Must specify a valid job type ' + type

    priority ?= DEFAULT_PRIORITY
    ttlMs ?= DEFAULT_TTL_MS
    delayMs ?= 0
    jobOptions = {
      priority, timeout: ttlMs, removeOnComplete: true
    }
    if delayMs
      jobOptions.delayMs = delayMs
    if maxAttempts
      jobOptions.attempts = maxAttempts
    if backoff
      jobOptions.backoff = backoff

    queues[queueKey].add type, job, jobOptions
    .then (job) ->
      if not waitForCompletion
        null
      else
        job.finished()

module.exports = new JobCreateService()
