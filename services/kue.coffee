kue = require 'kue'
Redis = require 'ioredis'
_ = require 'lodash'

config = require '../config'

KUE_SHUTDOWN_TIME_MS = 2000

q = kue.createQueue {
  redis: {
    # kue makes 2 instances
    # http://stackoverflow.com/questions/30944960/kue-worker-with-with-createclientfactory-only-subscriber-commands-may-be-used
    createClientFactory: ->
      new Redis {
        port: config.REDIS.PORT
        host: config.REDIS.KUE_HOST
      }
  }
}

q.on 'error', (err) ->
  console.log err

process.once 'SIGTERM', (sig) ->
  q.shutdown KUE_SHUTDOWN_TIME_MS, (err) ->
    console.log 'Kue shutdown: ', err or ''
    process.exit 0

module.exports = q
