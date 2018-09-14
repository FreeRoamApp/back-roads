router = require 'exoid-router'

AmenityCtrl = require './controllers/amenity'
AuthCtrl = require './controllers/auth'
BanCtrl = require './controllers/ban'
CategoryCtrl = require './controllers/category'
CampgroundCtrl = require './controllers/campground'
CampgroundReviewCtrl = require './controllers/campground_review'
ConversationMessageCtrl = require './controllers/conversation_message'
ConversationCtrl = require './controllers/conversation'
GroupCtrl = require './controllers/group'
GroupAuditLogCtrl = require './controllers/group_audit_log'
GroupUserCtrl = require './controllers/group_user'
GroupRoleCtrl = require './controllers/group_role'
ItemCtrl = require './controllers/item'
NotificationCtrl = require './controllers/notification'
NpsCtrl = require './controllers/nps'
ProductCtrl = require './controllers/product'
PushTokenCtrl = require './controllers/push_token'
ThreadCtrl = require './controllers/thread'
ThreadCommentCtrl = require './controllers/thread_comment'
ThreadVoteCtrl = require './controllers/thread_vote'
UserCtrl = require './controllers/user'
UserBlockCtrl = require './controllers/user_block'
UserFollowerCtrl = require './controllers/user_follower'

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
.on 'categories.getAll', authed CategoryCtrl.getAll

.on 'conversations.create', authed ConversationCtrl.create
.on 'conversations.updateById', authed ConversationCtrl.updateById
.on 'conversations.markReadById', authed ConversationCtrl.markReadById
.on 'conversations.getAll', authed ConversationCtrl.getAll
.on 'conversations.getAllByGroupId', authed ConversationCtrl.getAllByGroupId
.on 'conversations.getById', authed ConversationCtrl.getById
.on 'conversations.setOrderByGroupId', authed ConversationCtrl.setOrderByGroupId

.on 'conversationMessages.create', authed ConversationMessageCtrl.create
.on 'conversationMessages.deleteById', authed ConversationMessageCtrl.deleteById
.on 'conversationMessages.deleteAllByGroupIdAndUserId',
  authed ConversationMessageCtrl.deleteAllByGroupIdAndUserId
.on 'conversationMessages.getLastTimeByMeAndConversationId',
  authed ConversationMessageCtrl.getLastTimeByMeAndConversationId
.on 'conversationMessages.uploadImage', authed ConversationMessageCtrl.uploadImage
.on 'conversationMessages.getAllByConversationId',
  authed ConversationMessageCtrl.getAllByConversationId
.on 'conversationMessages.unsubscribeByConversationId',
  authed ConversationMessageCtrl.unsubscribeByConversationId

.on 'groups.create', authed GroupCtrl.create
.on 'groups.updateById', authed GroupCtrl.updateById
.on 'groups.joinById', authed GroupCtrl.joinById
.on 'groups.leaveById', authed GroupCtrl.leaveById
.on 'groups.getAll', authed GroupCtrl.getAll
.on 'groups.getAllByUserId', authed GroupCtrl.getAllByUserId
.on 'groups.getAllConversationsById', authed GroupCtrl.getAllConversationsById
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

.on 'items.getBySlug', authed ItemCtrl.getBySlug
.on 'items.getAll', authed ItemCtrl.getAll
.on 'items.getAllByCategory', authed ItemCtrl.getAllByCategory
.on 'items.search', authed ItemCtrl.search

.on 'notifications.getAll', authed NotificationCtrl.getAll

.on 'nps.create', authed NpsCtrl.create

# places (shared routes for the most part)
.on 'amenities.getBySlug', authed AmenityCtrl.getBySlug
.on 'amenities.search', authed AmenityCtrl.search

.on 'campgrounds.getBySlug', authed CampgroundCtrl.getBySlug
.on 'campgrounds.search', authed CampgroundCtrl.search
# end places

.on 'products.getBySlug', authed ProductCtrl.getBySlug
.on 'products.getAllByItemSlug', authed ProductCtrl.getAllByItemSlug

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert
.on 'pushTokens.subscribeToTopic', authed PushTokenCtrl.subscribeToTopic

# reviews (shared routes for the most part)
.on 'campgroundReviews.getAllByParentId',
  authed CampgroundReviewCtrl.getAllByParentId
.on 'campgroundReviews.search', authed CampgroundReviewCtrl.search
.on 'campgroundReviews.upsert', authed CampgroundReviewCtrl.upsert
.on 'campgroundReviews.uploadImage', authed CampgroundReviewCtrl.uploadImage
# end reviews

.on 'threads.upsert', authed ThreadCtrl.upsert
.on 'threads.getAll', authed ThreadCtrl.getAll
.on 'threads.getById', authed ThreadCtrl.getById
.on 'threads.getBySlug', authed ThreadCtrl.getBySlug
.on 'threads.voteById', authed ThreadCtrl.voteById
.on 'threads.pinById', authed ThreadCtrl.pinById
.on 'threads.unpinById', authed ThreadCtrl.unpinById
.on 'threads.deleteById', authed ThreadCtrl.deleteById
.on 'threads.uploadImage', authed ThreadCtrl.uploadImage

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

.on 'users.getMe', authed UserCtrl.getMe
.on 'users.getById', authed UserCtrl.getById
.on 'users.getByUsername', authed UserCtrl.getByUsername
.on 'users.getCountry', authed UserCtrl.getCountry
.on 'users.setPartner', authed UserCtrl.setPartner
.on 'users.getPartner', authed UserCtrl.getPartner

.on 'userFollowers.getAllFollowingIds',
  authed UserFollowerCtrl.getAllFollowingIds
.on 'userFollowers.getAllFollowerIds',
  authed UserFollowerCtrl.getAllFollowerIds
.on 'userFollowers.getAllFollowing', authed UserFollowerCtrl.getAllFollowing
.on 'userFollowers.getAllFollowers', authed UserFollowerCtrl.getAllFollowers
.on 'userFollowers.followByUserId', authed UserFollowerCtrl.followByUserId
.on 'userFollowers.unfollowByUserId', authed UserFollowerCtrl.unfollowByUserId

.on 'userBlocks.getAll', authed UserBlockCtrl.getAll
.on 'userBlocks.getAllIds', authed UserBlockCtrl.getAllIds
.on 'userBlocks.blockByUserId', authed UserBlockCtrl.blockByUserId
.on 'userBlocks.unblockByUserId', authed UserBlockCtrl.unblockByUserId
