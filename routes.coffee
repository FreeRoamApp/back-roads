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
.on 'users.getByUuid', authed UserCtrl.getByUuid
.on 'users.getByUsername', authed UserCtrl.getByUsername
.on 'users.getCountry', authed UserCtrl.getCountry

.on 'categories.getAll', authed CategoryCtrl.getAll

.on 'groups.create', authed GroupCtrl.create
.on 'groups.updateByUuid', authed GroupCtrl.updateByUuid
.on 'groups.joinByUuid', authed GroupCtrl.joinByUuid
.on 'groups.leaveByUuid', authed GroupCtrl.leaveByUuid
.on 'groups.getAll', authed GroupCtrl.getAll
.on 'groups.getAllByUserUuid', authed GroupCtrl.getAllByUserUuid
.on 'groups.getAllConversationByUuid', authed GroupCtrl.getAllConversationByUuid
.on 'groups.getByUuid', authed GroupCtrl.getByUuid
.on 'groups.getById', authed GroupCtrl.getById
.on 'groups.sendNotificationByUuid', authed GroupCtrl.sendNotificationByUuid

.on 'groupAuditLogs.getAllByGroupUuid',
  authed GroupAuditLogCtrl.getAllByGroupUuid

.on 'groupUsers.addRoleByGroupUuidAndUserUuid',
  authed GroupUserCtrl.addRoleByGroupUuidAndUserUuid
.on 'groupUsers.removeRoleByGroupUuidAndUserUuid',
  authed GroupUserCtrl.removeRoleByGroupUuidAndUserUuid
.on 'groupUsers.addXpByGroupUuidAndUserUuid',
  authed GroupUserCtrl.addXpByGroupUuidAndUserUuid
.on 'groupUsers.getByGroupUuidAndUserUuid',
  authed GroupUserCtrl.getByGroupUuidAndUserUuid
.on 'groupUsers.getTopByGroupUuid', authed GroupUserCtrl.getTopByGroupUuid
.on 'groupUsers.getMeSettingsByGroupUuid',
  authed GroupUserCtrl.getMeSettingsByGroupUuid
.on 'groupUsers.updateMeSettingsByGroupUuid',
  authed GroupUserCtrl.updateMeSettingsByGroupUuid
.on 'groupUsers.getOnlineCountByGroupUuid',
  authed GroupUserCtrl.getOnlineCountByGroupUuid

.on 'groupRoles.getAllByGroupUuid', authed GroupRoleCtrl.getAllByGroupUuid
.on 'groupRoles.createByGroupUuid', authed GroupRoleCtrl.createByGroupUuid
.on 'groupRoles.updatePermissions', authed GroupRoleCtrl.updatePermissions
.on 'groupRoles.deleteByGroupUuidAndRoleUuid',
  authed GroupRoleCtrl.deleteByGroupUuidAndRoleUuid

.on 'items.getByUuid', authed ItemCtrl.getByUuid
.on 'items.getAll', authed ItemCtrl.getAll
.on 'items.getAllByCategory', authed ItemCtrl.getAllByCategory
.on 'items.search', authed ItemCtrl.search

.on 'places.getByUuid', authed PlaceCtrl.getByUuid
.on 'places.search', authed PlaceCtrl.search

.on 'products.getByUuid', authed ProductCtrl.getByUuid
.on 'products.getAllByItemId', authed ProductCtrl.getAllByItemId

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert
.on 'pushTokens.subscribeToTopic', authed PushTokenCtrl.subscribeToTopic

.on 'threads.upsert', authed ThreadCtrl.upsert
.on 'threads.getAll', authed ThreadCtrl.getAll
.on 'threads.getByUuid', authed ThreadCtrl.getByUuid
.on 'threads.getById', authed ThreadCtrl.getById
.on 'threads.voteByUuid', authed ThreadCtrl.voteByUuid
.on 'threads.pinByUuid', authed ThreadCtrl.pinByUuid
.on 'threads.unpinByUuid', authed ThreadCtrl.unpinByUuid
.on 'threads.deleteByUuid', authed ThreadCtrl.deleteByUuid

.on 'threadVotes.upsertByParent',
  authed ThreadVoteCtrl.upsertByParent

.on 'threadComments.create', authed ThreadCommentCtrl.create
.on 'threadComments.flag', authed ThreadCommentCtrl.flag
.on 'threadComments.getAllByThreadUuid',
  authed ThreadCommentCtrl.getAllByThreadUuid
.on 'threadComments.deleteByThreadComment',
  authed ThreadCommentCtrl.deleteByThreadComment
.on 'threadComments.deleteAllByGroupUuidAndUserUuid',
  authed ThreadCommentCtrl.deleteAllByGroupUuidAndUserUuid

.on 'time.get', authed -> {now: new Date()}

.on 'notifications.getAll', authed NotificationCtrl.getAll

.on 'nps.create', authed NpsCtrl.create
