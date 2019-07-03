_ = require 'lodash'
Promise = require 'bluebird'
kue = require 'kue'

KueService = require './kue'
CacheService = require './cache'
config = require '../config'

DEFAULT_PRIORITY = 0
DEFAULT_TTL_MS = 60 * 1000 * 9 # 9 minutes
IDLE_PROCESS_KILL_TIME_MS = 300 * 1000 # 5 min
PAUSE_EXTEND_BUFFER_MS = 5000
KUE_LOCK_EXPIRE_SECONDS = 30
STUCK_JOB_INTERVAL_MS = 5000

JOB_TYPES =
  DEFAULT: 'free_roam:default'
  DAILY_UPDATE_PLACE: 'free_roam:daily_update_place'

CacheService.lock CacheService.KEYS.KUE_WATCH_STUCK, ->
  console.log 'watching stuck jobs'
  KueService.watchStuckJobs STUCK_JOB_INTERVAL_MS
, {expireSeconds: KUE_LOCK_EXPIRE_SECONDS}

class KueCreateService
  JOB_TYPES: JOB_TYPES

  constructor: ->
    @workers = {} # pause/resume with this

  # getStats: ->
  #   redis.client().zrange(redis.client().getKey('jobs:' + type + ':' + state)
  #   kue.Job.rangeByState 'inactive', 0, 5000, 'asc', (err, selectedJobs) ->

  clean: ({types, minStuckTimeMs} = {}) ->
    types ?= ['failed', 'complete', 'inactive', 'active']
    Promise.map types, (type) ->
      new Promise (resolve, reject) ->
        kue.Job.rangeByState type, 0, 5000, 'asc', (err, selectedJobs) ->
          console.log 'cleaning ', type, selectedJobs?.length
          if err
            reject err
          resolve Promise.each selectedJobs, (job) ->
            lastUpdate = Date.now() - parseInt(job?.updated_at)
            if not minStuckTimeMs or lastUpdate > minStuckTimeMs
              console.log 'delete stuck', type, job.type
              try
                job.remove (err) ->
                  if err
                    reject(err)
                  else
                    resolve()
              catch err
                reject err

  pauseWorker: (kueWorkerId, {killTimeMs, resumeAfterTimeMs}) =>
    if resumeAfterTimeMs
      extendMs = resumeAfterTimeMs + killTimeMs + PAUSE_EXTEND_BUFFER_MS
      worker?.lock?.extend? extendMs

    killTimeMs ?= 5000
    worker = @workers[kueWorkerId]
    console.log 'pause worker', Boolean worker
    new Promise (resolve, reject) ->
      unless worker
        console.log 'skip pause'
        reject new Error('worker doesn\'t exist')
      try
        console.log worker?.id
        worker?.ctx?.pause? killTimeMs, (err) ->
          if err
            reject err
          else
            resolve()
      catch err
        console.log err
    .then ->
      if resumeAfterTimeMs?
        # TODO: use redis/queue for this instead of setTimeout?
        setTimeout ->
          try
            console.log 'resume worker', worker?.id
            worker?.ctx?.resume?()
          catch err
            console.log err
        , Math.max resumeAfterTimeMs, killTimeMs

  killWorker: (kueWorkerId, {killTimeMs} = {}) =>
    killTimeMs ?= 5000
    console.log 'kill worker'
    new Promise (resolve, reject) =>
      worker = @workers[kueWorkerId]
      try
        worker?.ctx?.pause? killTimeMs, resolve
      catch err
        console.log 'kill err', err
    .catch (err) ->
      console.log 'kill promise err', err
    .then =>
      delete @workers[kueWorkerId]

  # FIFO, ability to pause worker for chat/kueWorkerId
  listenOnce: (kueWorkerId) =>
    key = "#{CacheService.LOCK_PREFIXES.KUE_PROCESS}:#{kueWorkerId}"
    expireSeconds = if config.ENV is config.ENVS.DEV then 3 else 30
    CacheService.lock key, (lock) =>
      # FIXME FIXME: don't keep repeating failed message
      lastUpdateTime = Date.now()
      clearExtendInterval = -> clearInterval extendInterval
      extendInterval = setInterval =>
        if Date.now() - lastUpdateTime > IDLE_PROCESS_KILL_TIME_MS
          @killWorker kueWorkerId
          .then clearExtendInterval
          .catch clearExtendInterval
        else
          lock.extend expireSeconds * 1000
          .catch clearExtendInterval
      , 1000 * expireSeconds / 2

      KueService.process kueWorkerId, 1, (job, ctx, done) =>
        # we queue this fn up again so it can be run on any
        # process/server, in case we have one chatId that is too heavy for a CPU
        lastUpdateTime = Date.now()
        @workers[kueWorkerId] = {ctx, lock, id: job.id}
        @createJob _.defaults {isSynchronous: false}, job.data
        .then (response) ->
          done null, response
        .catch (err) ->
          done err
    , {
      expireSeconds: expireSeconds
    }

  createJob: (options) =>
    {job, priority, ttlMs, delayMs, type, isSynchronous, kueWorkerId,
      maxAttempts, backoff, waitForCompletion} = options

    new Promise (resolve, reject) =>
      unless type? and _.includes _.values(JOB_TYPES), type
        throw new Error 'Must specify a valid job type ' + type
      # create process for this queue, locked so only one worker manages it
      # (so it's fifo, one at a time)
      (if isSynchronous
        kueWorkerId ?= 'default_worker'
        @listenOnce kueWorkerId
        .then ->
          KueService.create kueWorkerId, options
      else
        kueJob = KueService.create type, _.defaults(job, {
          title: type # for kue dashboard
        })
        Promise.resolve kueJob)
      .then (kueJob) ->

        priority ?= DEFAULT_PRIORITY
        ttlMs ?= DEFAULT_TTL_MS
        delayMs ?= 0

        kueJob
        .priority priority
        .ttl ttlMs
        .removeOnComplete true

        if delayMs
          kueJob = kueJob.delay delayMs

        if maxAttempts
          kueJob = kueJob.attempts maxAttempts

        if backoff
          kueJob = kueJob.backoff {delay: backoff, type: 'fixed'}

        kueJob.save (err) ->
          if err
            console.log 'save err', err
            reject err
          else if not waitForCompletion
            resolve()

        if waitForCompletion
          kueJob.on 'complete', (response) ->
            resolve response
          kueJob.on 'failed', (err) ->
            console.log 'job failed', type, err
            reject()
          kueJob.on 'ttl exceeded', (err) ->
            console.log 'job timed out', type, err
            reject()

module.exports = new KueCreateService()
