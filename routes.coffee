router = require 'exoid-router'

AuthCtrl = require './controllers/auth'
NotificationCtrl = require './controllers/notification'
NpsCtrl = require './controllers/nps'
PushTokenCtrl = require './controllers/push_token'
UserCtrl = require './controllers/user'

authed = (handler) ->
  unless handler?
    return null

  (body, req, rest...) ->
    unless req.user?
      router.throw status: 401, info: 'Unauthorized', ignoreLog: true

    handler body, req, rest...

module.exports = router
###################
# Public Routes   #
###################
.on 'auth.join', AuthCtrl.join
.on 'auth.login', AuthCtrl.login
.on 'auth.loginUsername', AuthCtrl.loginUsername

###################
# Authed Routes   #
###################
.on 'users.getMe', authed UserCtrl.getMe
.on 'users.getById', authed UserCtrl.getById
.on 'users.getByUsername', authed UserCtrl.getByUsername
.on 'users.getCountry', authed UserCtrl.getCountry

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert
.on 'pushTokens.subscribeToTopic', authed PushTokenCtrl.subscribeToTopic

.on 'time.get', authed -> {now: new Date()}

.on 'notifications.getAll', authed NotificationCtrl.getAll

.on 'nps.create', authed NpsCtrl.create
