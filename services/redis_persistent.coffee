Redis = require 'ioredis'
_ = require 'lodash'

config = require '../config'

# separated from redis_cache since i expect that one to go oom more easily

client = new Redis {
  port: config.REDIS.PORT
  host: config.REDIS.PERSISTENT_HOST
}

events = ['connect', 'ready', 'error', 'close', 'reconnecting', 'end']
_.map events, (event) ->
  client.on event, ->
    console.log config.REDIS.PERSISTENT_HOST
    console.log "redislog persistent #{event}"

module.exports = client
