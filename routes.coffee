router = require 'exoid-router'

AuthCtrl = require './controllers/auth'
BanCtrl = require './controllers/ban'
CategoryCtrl = require './controllers/category'
GroupCtrl = require './controllers/group'
GroupAuditLogCtrl = require './controllers/group_audit_log'
GroupUserCtrl = require './controllers/group_user'
GroupRoleCtrl = require './controllers/group_role'
ItemCtrl = require './controllers/item'
NotificationCtrl = require './controllers/notification'
NpsCtrl = require './controllers/nps'
PlaceCtrl = require './controllers/place'
ProductCtrl = require './controllers/product'
PushTokenCtrl = require './controllers/push_token'
ThreadCtrl = require './controllers/thread'
ThreadCommentCtrl = require './controllers/thread_comment'
ThreadVoteCtrl = require './controllers/thread_vote'
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

.on 'groups.create', authed GroupCtrl.create
.on 'groups.updateById', authed GroupCtrl.updateById
.on 'groups.joinById', authed GroupCtrl.joinById
.on 'groups.leaveById', authed GroupCtrl.leaveById
.on 'groups.getAll', authed GroupCtrl.getAll
.on 'groups.getAllByUserId', authed GroupCtrl.getAllByUserId
.on 'groups.getAllConversationById', authed GroupCtrl.getAllConversationById
.on 'groups.getById', authed GroupCtrl.getById
.on 'groups.getBySlug', authed GroupCtrl.getBySlug
.on 'groups.sendNotificationById', authed GroupCtrl.sendNotificationById

.on 'groupAuditLogs.getAllByGroupId',
  authed GroupAuditLogCtrl.getAllByGroupId

.on 'groupUsers.addRoleByGroupIdAndUserId',
  authed GroupUserCtrl.addRoleByGroupIdAndUserId
.on 'groupUsers.removeRoleByGroupIdAndUserId',
  authed GroupUserCtrl.removeRoleByGroupIdAndUserId
.on 'groupUsers.addXpByGroupIdAndUserId',
  authed GroupUserCtrl.addXpByGroupIdAndUserId
.on 'groupUsers.getByGroupIdAndUserId',
  authed GroupUserCtrl.getByGroupIdAndUserId
.on 'groupUsers.getTopByGroupId', authed GroupUserCtrl.getTopByGroupId
.on 'groupUsers.getMeSettingsByGroupId',
  authed GroupUserCtrl.getMeSettingsByGroupId
.on 'groupUsers.updateMeSettingsByGroupId',
  authed GroupUserCtrl.updateMeSettingsByGroupId
.on 'groupUsers.getOnlineCountByGroupId',
  authed GroupUserCtrl.getOnlineCountByGroupId

.on 'groupRoles.getAllByGroupId', authed GroupRoleCtrl.getAllByGroupId
.on 'groupRoles.createByGroupId', authed GroupRoleCtrl.createByGroupId
.on 'groupRoles.updatePermissions', authed GroupRoleCtrl.updatePermissions
.on 'groupRoles.deleteByGroupIdAndRoleId',
  authed GroupRoleCtrl.deleteByGroupIdAndRoleId

.on 'items.getById', authed ItemCtrl.getById
.on 'items.getAll', authed ItemCtrl.getAll
.on 'items.getAllByCategory', authed ItemCtrl.getAllByCategory
.on 'items.search', authed ItemCtrl.search

.on 'places.getById', authed PlaceCtrl.getById
.on 'places.search', authed PlaceCtrl.search

.on 'products.getById', authed ProductCtrl.getById
.on 'products.getAllByItemSlug', authed ProductCtrl.getAllByItemSlug

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert
.on 'pushTokens.subscribeToTopic', authed PushTokenCtrl.subscribeToTopic

.on 'threads.upsert', authed ThreadCtrl.upsert
.on 'threads.getAll', authed ThreadCtrl.getAll
.on 'threads.getById', authed ThreadCtrl.getById
.on 'threads.getBySlug', authed ThreadCtrl.getBySlug
.on 'threads.voteById', authed ThreadCtrl.voteById
.on 'threads.pinById', authed ThreadCtrl.pinById
.on 'threads.unpinById', authed ThreadCtrl.unpinById
.on 'threads.deleteById', authed ThreadCtrl.deleteById

.on 'threadVotes.upsertByParent',
  authed ThreadVoteCtrl.upsertByParent

.on 'threadComments.create', authed ThreadCommentCtrl.create
.on 'threadComments.flag', authed ThreadCommentCtrl.flag
.on 'threadComments.getAllByThreadId',
  authed ThreadCommentCtrl.getAllByThreadId
.on 'threadComments.deleteByThreadComment',
  authed ThreadCommentCtrl.deleteByThreadComment
.on 'threadComments.deleteAllByGroupIdAndUserId',
  authed ThreadCommentCtrl.deleteAllByGroupIdAndUserId

.on 'time.get', authed -> {now: new Date()}

.on 'notifications.getAll', authed NotificationCtrl.getAll

.on 'nps.create', authed NpsCtrl.create
