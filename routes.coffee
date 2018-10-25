router = require 'exoid-router'

AmenityCtrl = require './controllers/amenity'
AuthCtrl = require './controllers/auth'
BanCtrl = require './controllers/ban'
CategoryCtrl = require './controllers/category'
CampgroundCtrl = require './controllers/campground'
CampgroundReviewCtrl = require './controllers/campground_review'
CampgroundAttachmentCtrl = require './controllers/campground_attachment'
CellTowerCtrl = require './controllers/cell_tower'
ConversationMessageCtrl = require './controllers/conversation_message'
ConversationCtrl = require './controllers/conversation'
GroupCtrl = require './controllers/group'
GroupAuditLogCtrl = require './controllers/group_audit_log'
GroupUserCtrl = require './controllers/group_user'
GroupRoleCtrl = require './controllers/group_role'
ItemCtrl = require './controllers/item'
LowClearanceCtrl = require './controllers/low_clearance'
NotificationCtrl = require './controllers/notification'
NpsCtrl = require './controllers/nps'
OvernightCtrl = require './controllers/overnight'
ProductCtrl = require './controllers/product'
PushTokenCtrl = require './controllers/push_token'
PushTopicCtrl = require './controllers/push_topic'
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

.on 'amenities.getBySlug', authed AmenityCtrl.getBySlug
.on 'amenities.search', authed AmenityCtrl.search
.on 'amenities.upsert', authed AmenityCtrl.upsert
.on 'amenities.deleteByRow', authed AmenityCtrl.deleteByRow

.on 'bans.getAllByGroupId', authed BanCtrl.getAllByGroupId
.on 'bans.getByGroupIdAndUserId', authed BanCtrl.getByGroupIdAndUserId
.on 'bans.banByGroupIdAndIp', authed BanCtrl.banByGroupIdAndIp
.on 'bans.banByGroupIdAndUserId', authed BanCtrl.banByGroupIdAndUserId
.on 'bans.unbanByGroupIdAndUserId', authed BanCtrl.unbanByGroupIdAndUserId

.on 'campgrounds.getBySlug', authed CampgroundCtrl.getBySlug
.on 'campgrounds.search', authed CampgroundCtrl.search
.on 'campgrounds.getAmenityBoundsById',
  authed CampgroundCtrl.getAmenityBoundsById
.on 'campgrounds.upsert', authed CampgroundCtrl.upsert

.on 'campgroundReviews.getById', authed CampgroundReviewCtrl.getById
.on 'campgroundReviews.deleteById', authed CampgroundReviewCtrl.deleteById
.on 'campgroundReviews.getAllByParentId',
  authed CampgroundReviewCtrl.getAllByParentId
.on 'campgroundReviews.search', authed CampgroundReviewCtrl.search
.on 'campgroundReviews.upsert', authed CampgroundReviewCtrl.upsert
.on 'campgroundReviews.uploadImage', authed CampgroundReviewCtrl.uploadImage

.on 'campgroundAttachments.getAllByParentId',
  authed CampgroundAttachmentCtrl.getAllByParentId
.on 'campgroundAttachments.deleteByRow',
  authed CampgroundAttachmentCtrl.deleteByRow

.on 'categories.getAll', authed CategoryCtrl.getAll

# .on 'cellTowers.getBySlug', authed CellTowerCtrl.getBySlug
.on 'cellTowers.search', authed CellTowerCtrl.search

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

.on 'lowClearances.search', authed LowClearanceCtrl.search

.on 'overnights.search', authed OvernightCtrl.search

.on 'notifications.getAll', authed NotificationCtrl.getAll

.on 'nps.create', authed NpsCtrl.create

.on 'products.getBySlug', authed ProductCtrl.getBySlug
.on 'products.getAllByItemSlug', authed ProductCtrl.getAllByItemSlug

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert

.on 'pushTopics.subscribe', authed PushTopicCtrl.subscribe
.on 'pushTopics.unsubscribe', authed PushTopicCtrl.unsubscribe
.on 'pushTopics.getAll', authed PushTopicCtrl.getAll

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
.on 'users.setAvatarImage', authed UserCtrl.setAvatarImage
.on 'users.setPartner', authed UserCtrl.setPartner
.on 'users.getPartner', authed UserCtrl.getPartner
.on 'users.upsert', authed UserCtrl.upsert

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
