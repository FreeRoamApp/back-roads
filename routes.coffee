router = require 'exoid-router'

AuthCtrl = require './controllers/auth'
CategoryCtrl = require './controllers/category'
ItemCtrl = require './controllers/item'
NotificationCtrl = require './controllers/notification'
NpsCtrl = require './controllers/nps'
PlaceCtrl = require './controllers/place'
ProductCtrl = require './controllers/product'
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

.on 'categories.getAll', authed CategoryCtrl.getAll

.on 'items.getById', authed ItemCtrl.getById
.on 'items.getAll', authed ItemCtrl.getAll
.on 'items.getAllByCategory', authed ItemCtrl.getAllByCategory
.on 'items.search', authed ItemCtrl.search

.on 'places.getById', authed PlaceCtrl.getById
.on 'places.search', authed PlaceCtrl.search

.on 'products.getById', authed ProductCtrl.getById
.on 'products.getAllByItemId', authed ProductCtrl.getAllByItemId

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert
.on 'pushTokens.subscribeToTopic', authed PushTokenCtrl.subscribeToTopic

.on 'time.get', authed -> {now: new Date()}

.on 'notifications.getAll', authed NotificationCtrl.getAll

.on 'nps.create', authed NpsCtrl.create
