fs = require 'fs'
_ = require 'lodash'
log = require 'loga'
cors = require 'cors'
express = require 'express'
Promise = require 'bluebird'
multer = require 'multer'
bodyParser = require 'body-parser'
cluster = require 'cluster'
http = require 'http'
socketIO = require 'socket.io'
# socketIORedis = require 'socket.io-redis'
Redis = require 'ioredis'

# memwatch = require 'memwatch-next'
#
# hd = undefined
# snapshotTaken = false
# memwatch.on 'stats', (stats) ->
#   # console.log 'stats:', stats
#   if snapshotTaken is false
#     hd = new (memwatch.HeapDiff)
#     snapshotTaken = true
#   else
#     # diff = hd.end()
#     snapshotTaken = false
#     # console.log(JSON.stringify(diff, null, '\t'))
#   return
# memwatch.on 'leak', (info) ->
#   console.log 'leak:', info
#   diff = hd.end()
#   hd = new (memwatch.HeapDiff)
#   snapshotTaken = false
#   console.log(JSON.stringify(diff, null, '\t'))
#   return


Joi = require 'joi'

config = require './config'
routes = require './routes'
cknex = require './services/cknex'
ScyllaSetupService = require './services/scylla_setup'
ElasticsearchSetupService = require './services/elasticsearch_setup'
AuthService = require './services/auth'
CronService = require './services/cron'
JobRunnerService = require './services/job_runner'
ConversationMessageCtrl = require './controllers/conversation_message'
HealthCtrl = require './controllers/health'
PaymentCtrl = require './controllers/payment'
SiteMapCtrl = require './controllers/site_map'
StreamService = require './services/stream'

if config.DEV_USE_HTTPS
  https = require 'https'
  fs = require 'fs'
  privateKey  = fs.readFileSync './bin/fr-dev.key'
  certificate = fs.readFileSync './bin/fr-dev.crt'
  credentials = {key: privateKey, cert: certificate}

MAX_FILE_SIZE_BYTES = 20 * 1000 * 1000 # 20MB
MAX_FIELD_SIZE_BYTES = 100 * 1000 # 100KB
FIVE_MINUTES_MS = 5 * 60 * 1000

Promise.config {warnings: false}

setup = ->
  models = fs.readdirSync('./models')
  scyllaTables = _.flatten _.map models, (modelFile) ->
    model = require('./models/' + modelFile)
    model?.getScyllaTables?() or []
  elasticSearchIndices = _.flatten _.map models, (modelFile) ->
    model = require('./models/' + modelFile)
    model?.getElasticSearchIndices?() or []

  shouldRunSetup = true or config.ENV is config.ENVS.PRODUCTION or
                    config.SCYLLA.CONTACT_POINTS[0] is 'localhost'

  Promise.all _.filter [
    if shouldRunSetup
      ScyllaSetupService.setup scyllaTables
      .then -> console.log 'scylla setup'
    if shouldRunSetup
      ElasticsearchSetupService.setup elasticSearchIndices
      .then -> console.log 'elasticsearch setup'
  ]
  .catch (err) ->
    console.log 'setup', err
  .tap ->
    console.log 'scylla & elasticsearch setup'
    cknex.enableErrors()
    CronService.start()
    console.log 'cron started'
    JobRunnerService.listen() # TODO: child instance too
    null # don't block

childSetup = ->
  # JobRunnerService.listen()
  cknex.enableErrors()
  return Promise.resolve null # don't block

app = express()

app.set 'x-powered-by', false

app.use cors()
app.use AuthService.middleware

# Before BodyParser middleware to preserve file stream
upload = multer
  limits:
    fields: 10
    fieldSize: MAX_FIELD_SIZE_BYTES
    fileSize: MAX_FILE_SIZE_BYTES
    files: 1

app.post '/upload', (req, res, next) ->
  schema = Joi.object().keys
    path: Joi.string()
    body: Joi.string().optional()
  .unknown()

  valid = Joi.validate req.query, schema, {presence: 'required', convert: false}

  if valid.error?
    log.error
      event: 'error'
      status: 400
      info: 'invalid /upload parameters'
      error: valid.error
    return res.status(400).json {status: 400, info: 'invalid upload parameters'}

  try
    path = req.query.path
    body = JSON.parse req.query.body or '{}'
  catch err
    log.error
      event: 'error'
      status: 400
      info: 'invalid /upload parameters'
      error: err
    return res.status(400).json {status: 400, info: 'invalid upload parameters'}

  new Promise (resolve, reject) ->
    upload.single('file') req, res, (err) ->
      if err
        return reject err
      resolve()
  .then ->
    routes.resolve path, body, req
  .then ({result, error, cache}) ->
    if error?
      res.status(error.status or 500).json error
    else
      res.json result
  .catch (err) ->
    log.error err
    next err


app.post '/payment/stripe', bodyParser.raw({ type: '*/*' }), PaymentCtrl.stripe

app.use bodyParser.json({limit: '1mb'})
# Avoid CORS preflight
app.use bodyParser.json({type: 'text/plain', limit: '1mb'})
app.use bodyParser.urlencoded {extended: true} # Kiip uses

app.get '/', (req, res) -> res.status(200).send 'ok'

# TODO: restrict to backroads.production
app.post '/conversationMessage/:id/card', ConversationMessageCtrl.updateCard

app.get '/ping', (req, res) -> res.send 'pong'

app.get '/healthcheck', HealthCtrl.check

app.get '/healthcheck/throw', HealthCtrl.checkThrow

app.get '/sitemap', SiteMapCtrl.getAll

# app.get '/migrate-trips', ->
#   sync = require './services/migrate_trips.coffee'
#   console.log sync
#   sync()

app.post '/log', (req, res) ->
  unless req.body?.event is 'client_error'
    return res.status(400).send 'must be type client_error'

  console.log JSON.stringify req.body
  log.warn req.body
  res.status(204).send()

app.get '/cleanJobFailed', (req, res) ->
  JobCreateService = require './services/job_create'
  JobCreateService.clean()
  .catch ->
    console.log 'job clean route fail'
  res.sendStatus 200

app.get '/mapImages', (req, res) ->
  console.log 'goooo'
  PlacesService = require './services/places'
  Campground = require './models/campground'
  go = (slug) ->
    Campground.getAllByMinSlug slug
    .then (campgrounds) ->
      console.log campgrounds.length
      Promise.each campgrounds, (campground) ->
        campground.type = 'campground'
        console.log 'MAP IMAGE', campground.slug
        PlacesService.setMapImage campground
        .catch (err) ->
          console.log 'FAIL', err
      .then ->
        next = _.last(campgrounds)?.slug
        console.log 'NEXT', next
        if next
          go next

  go req.query.minSlug or '0'
  res.sendStatus 200


server = if config.DEV_USE_HTTPS \
         then https.createServer credentials, app
         else http.createServer app
io = socketIO.listen server

setInterval ->
  console.log 'socket.io', io.engine.clientsCount
, FIVE_MINUTES_MS

# for now, this is unnecessary. lightning-rod is clientip,
# and stickCluster handles the cpus
# io.adapter socketIORedis {
#   pubClient: redisPub
#   subClient: redisSub
#   subEvent: config.REDIS.PREFIX + 'socketio:message'
# }
routes.setMiddleware AuthService.exoidMiddleware
routes.setDisconnect StreamService.exoidDisconnect
io.on 'connection', routes.onConnection

module.exports = {
  server
  setup
  childSetup
}
