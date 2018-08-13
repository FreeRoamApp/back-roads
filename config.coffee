_ = require 'lodash'
assertNoneMissing = require 'assert-none-missing'

env = process.env

# REDIS_PORT = if env.IS_STAGING is '1' then 6378 else 6379 # for cluster
REDIS_PORT = 6379
DEV_USE_HTTPS = process.env.DEV_USE_HTTPS and process.env.DEV_USE_HTTPS isnt '0'

config =
  NOTIFICATION_COLOR: '#fc373e'
  EMPTY_UUID: '00000000-0000-0000-0000-000000000000'

  # also in free-roam
  BASE_NAME_COLORS: ['#2196F3', '#8BC34A', '#FFC107', '#f44336', '#673AB7']
  VERBOSE: if env.VERBOSE then env.VERBOSE is '1' else true
  PORT: env.BACK_ROADS_PORT or 50000
  ENV: env.DEBUG_ENV or env.NODE_ENV
  IS_STAGING: env.IS_STAGING is '1'
  JWT_ES256_PRIVATE_KEY: env.JWT_ES256_PRIVATE_KEY
  JWT_ES256_PUBLIC_KEY: env.JWT_ES256_PUBLIC_KEY
  JWT_ISSUER: 'exoid'
  DEV_USE_HTTPS: DEV_USE_HTTPS
  MAX_CPU: env.BACK_ROADS_MAX_CPU or 1
  APN_CERT: env.BACK_ROADS_APN_CERT
  APN_KEY: env.BACK_ROADS_APN_KEY
  APN_PASSPHRASE: env.BACK_ROADS_APN_PASSPHRASE
  GOOGLE_PRIVATE_KEY_JSON: env.GOOGLE_PRIVATE_KEY_JSON
  GOOGLE_API_KEY: env.GOOGLE_API_KEY
  GOOGLE_API_KEY_MYSTIC: env.GOOGLE_API_KEY_MYSTIC
  CARD_CODE_MAX_LENGTH: 9999999999
  PCG_SEED: env.BACK_ROADS_PCG_SEED
  PT_UTC_OFFSET: -8
  IOS_BUNDLE_ID: 'app.freeroam.go'
  BACK_ROADS_API_URL: env.BACK_ROADS_API_URL
  VAPID_SUBJECT: env.BACK_ROADS_VAPID_SUBJECT
  VAPID_PUBLIC_KEY: env.BACK_ROADS_VAPID_PUBLIC_KEY
  VAPID_PRIVATE_KEY: env.BACK_ROADS_VAPID_PRIVATE_KEY
  HONEYPOT_ACCESS_KEY: env.HONEYPOT_ACCESS_KEY
  GA_ID: env.BACK_ROADS_GA_ID
  GOOGLE:
    CLIENT_ID: env.GOOGLE_CLIENT_ID
    CLIENT_SECRET: env.GOOGLE_CLIENT_SECRET
    REFRESH_TOKEN: env.GOOGLE_REFRESH_TOKEN
    REDIRECT_URL: 'urn:ietf:wg:oauth:2.0:oob'
  GMAIL:
    USER: env.GMAIL_USER
    PASS: env.GMAIL_PASS
  TWITTER:
    CONSUMER_KEY: env.TWITTER_CONSUMER_KEY
    CONSUMER_SECRET: env.TWITTER_CONSUMER_SECRET
    ACCESS_TOKEN: env.TWITTER_ACCESS_TOKEN
    ACCESS_TOKEN_SECRET: env.TWITTER_ACCESS_TOKEN_SECRET
  REDIS:
    PREFIX: 'free_roam'
    PUB_SUB_PREFIX: 'free_roam_pub_sub'
    PORT: REDIS_PORT
    KUE_HOST: env.REDIS_KUE_HOST
    PUB_SUB_HOST: env.REDIS_PUB_SUB_HOST
    CACHE_HOST: env.REDIS_CACHE_HOST
    PERSISTENT_HOST: env.REDIS_PERSISTENT_HOST
  CDN_HOST: env.CDN_HOST
  SCYLLA:
    KEYSPACE: 'free_roam'
    PORT: 9042
    CONTACT_POINTS: env.SCYLLA_CONTACT_POINTS.split(',')
  ELASTICSEARCH:
    PORT: 9200
    HOST: env.ELASTICSEARCH_HOST
  AWS:
    ACCESS_KEY_ID: env.AWS_ACCESS_KEY_ID
    SECRET_ACCESS_KEY: env.AWS_SECRET_ACCESS_KEY
  ENVS:
    DEV: 'development'
    PROD: 'production'
    TEST: 'test'

assertNoneMissing config

module.exports = config
