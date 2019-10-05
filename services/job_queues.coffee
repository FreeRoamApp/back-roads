Queue = require 'bull'
Redis = require 'ioredis'
_ = require 'lodash'

config = require '../config'

module.exports = {
  SES:
    new Queue 'SES', {
      redis: {
        port: config.REDIS.PORT
        host: config.REDIS.CACHE_HOST
      }
      limiter: # 10 calls per second
        max: config.AWS.SES_LIMIT_PER_SECOND
        duration: 1000
    }
  DEFAULT:
    new Queue 'DEFAULT', {
      redis: {
        port: config.REDIS.PORT
        host: config.REDIS.CACHE_HOST
      }
  }
}
