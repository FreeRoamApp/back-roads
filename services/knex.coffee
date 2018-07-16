knex = require 'knex'
cluster = require 'cluster'

config = require '../config'

# we can probably bump this up when we have more
# postgres connections / larger pools
THIRTY_SECONDS_MS = 30 * 1000
FIVE_MINUTES_MS = 5 * 60 * 1000

knexInstance = knex {
  client: 'pg',
  connection: {
    host: config.POSTGRES.HOST
    user: config.POSTGRES.USER
    password: config.POSTGRES.PASS
    database: config.POSTGRES.DB
  }
  useNullAsDefault: true
  debug: false
  acquireConnectionTimeout: FIVE_MINUTES_MS
  pool:
    requestTimeout: THIRTY_SECONDS_MS
    # for some reason resources get stuck in queue?
    evictionRunIntervalMillis: THIRTY_SECONDS_MS
    # 2 for cron jobs stale data. otherwise get
    # https://github.com/tgriesser/knex/issues/1381
    # not sure if fixes / why fixes. or if it makes it better at all?
    max: 2 # if cluster.isMaster then 2 else 1
          # 3 * 6 * 4 cpu replicas is 72 connections. can have up to 100
           # TODO bump up when 100 connection limit is increased
           # https://issuetracker.google.com/issues/37271935
}

module.exports = knexInstance
