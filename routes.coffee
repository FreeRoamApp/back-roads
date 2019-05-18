router = require 'exoid-router'

AmenityCtrl = require './controllers/amenity'
AmenityReviewCtrl = require './controllers/amenity_review'
AmenityAttachmentCtrl = require './controllers/amenity_attachment'
AuthCtrl = require './controllers/auth'
BanCtrl = require './controllers/ban'
CategoryCtrl = require './controllers/category'
CampgroundCtrl = require './controllers/campground'
CampgroundReviewCtrl = require './controllers/campground_review'
CampgroundAttachmentCtrl = require './controllers/campground_attachment'
CellTowerCtrl = require './controllers/cell_tower'
CheckInCtrl = require './controllers/check_in'
ConnectionCtrl = require './controllers/connection'
ConversationMessageCtrl = require './controllers/conversation_message'
ConversationCtrl = require './controllers/conversation'
CoordinateCtrl = require './controllers/coordinate'
GeocoderCtrl = require './controllers/geocoder'
GroupCtrl = require './controllers/group'
GroupAuditLogCtrl = require './controllers/group_audit_log'
GroupUserCtrl = require './controllers/group_user'
GroupRoleCtrl = require './controllers/group_role'
ItemCtrl = require './controllers/item'
LowClearanceCtrl = require './controllers/low_clearance'
NotificationCtrl = require './controllers/notification'
NpsCtrl = require './controllers/nps'
OvernightCtrl = require './controllers/overnight'
OvernightReviewCtrl = require './controllers/overnight_review'
OvernightAttachmentCtrl = require './controllers/overnight_attachment'
PlaceAttachmentCtrl = require './controllers/campground_attachment' # HACK: use since place_review_base isn't instantiated
PlaceReviewCtrl = require './controllers/campground_review' # HACK: use since place_review_base isn't instantiated
ProductCtrl = require './controllers/product'
PushTokenCtrl = require './controllers/push_token'
SubscriptionCtrl = require './controllers/subscription'
ThreadCtrl = require './controllers/thread'
TripCtrl = require './controllers/trip'
UserCtrl = require './controllers/user'
UserBlockCtrl = require './controllers/user_block'
UserLocationCtrl = require './controllers/user_location'
UserRigCtrl = require './controllers/user_rig'
UserSettingsCtrl = require './controllers/user_settings'
CommentCtrl = require './controllers/comment'
VoteCtrl = require './controllers/vote'

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

.on 'amenityReviews.getById', authed AmenityReviewCtrl.getById
.on 'amenityReviews.deleteById', authed AmenityReviewCtrl.deleteById
.on 'amenityReviews.getAllByParentId',
  authed AmenityReviewCtrl.getAllByParentId
.on 'amenityReviews.search', authed AmenityReviewCtrl.search
.on 'amenityReviews.upsert', authed AmenityReviewCtrl.upsert
.on 'amenityReviews.uploadImage', authed AmenityReviewCtrl.uploadImage

.on 'amenityAttachments.getAllByParentId',
  authed AmenityAttachmentCtrl.getAllByParentId
.on 'amenityAttachments.deleteByRow',
  authed AmenityAttachmentCtrl.deleteByRow

.on 'bans.getAllByGroupId', authed BanCtrl.getAllByGroupId
.on 'bans.getByGroupIdAndUserId', authed BanCtrl.getByGroupIdAndUserId
.on 'bans.banByGroupIdAndIp', authed BanCtrl.banByGroupIdAndIp
.on 'bans.banByGroupIdAndUserId', authed BanCtrl.banByGroupIdAndUserId
.on 'bans.unbanByGroupIdAndUserId', authed BanCtrl.unbanByGroupIdAndUserId

.on 'campgrounds.getBySlug', authed CampgroundCtrl.getBySlug
.on 'campgrounds.deleteByRow', authed CampgroundCtrl.deleteByRow
.on 'campgrounds.search', authed CampgroundCtrl.search
.on 'campgrounds.searchNearby', authed CampgroundCtrl.searchNearby
.on 'campgrounds.getNearestAmenitiesById',
  authed CampgroundCtrl.getNearestAmenitiesById
.on 'campgrounds.upsert', authed CampgroundCtrl.upsert

.on 'campgroundReviews.getById', authed CampgroundReviewCtrl.getById
.on 'campgroundReviews.deleteById', authed CampgroundReviewCtrl.deleteById
.on 'campgroundReviews.getAllByParentId',
  authed CampgroundReviewCtrl.getAllByParentId
.on 'campgroundReviews.search', authed CampgroundReviewCtrl.search
.on 'campgroundReviews.upsert', authed CampgroundReviewCtrl.upsert
.on 'campgroundReviews.upsertRatingOnly',
  authed CampgroundReviewCtrl.upsertRatingOnly
.on 'campgroundReviews.uploadImage', authed CampgroundReviewCtrl.uploadImage

.on 'campgroundAttachments.getAllByParentId',
  authed CampgroundAttachmentCtrl.getAllByParentId
.on 'campgroundAttachments.deleteByRow',
  authed CampgroundAttachmentCtrl.deleteByRow

.on 'categories.getAll', authed CategoryCtrl.getAll

# .on 'cellTowers.getBySlug', authed CellTowerCtrl.getBySlug
.on 'cellTowers.search', authed CellTowerCtrl.search

.on 'checkIns.getAll', authed CheckInCtrl.getAll
.on 'checkIns.getById', authed CheckInCtrl.getById
.on 'checkIns.uploadImage', authed CheckInCtrl.uploadImage
.on 'checkIns.upsert', authed CheckInCtrl.upsert
.on 'checkIns.deleteByRow', authed CheckInCtrl.deleteByRow

.on 'comments.create', authed CommentCtrl.create
.on 'comments.flag', authed CommentCtrl.flag
.on 'comments.getAllByTopId',
  authed CommentCtrl.getAllByTopId
.on 'comments.deleteByComment',
  authed CommentCtrl.deleteByComment
.on 'comments.deleteAllByGroupIdAndUserId',
  authed CommentCtrl.deleteAllByGroupIdAndUserId

.on 'connections.getAllIdsByType', authed ConnectionCtrl.getAllIdsByType
.on 'connections.getAllByType', authed ConnectionCtrl.getAllByType
.on 'connections.getAllGrouped', authed ConnectionCtrl.getAllGrouped
.on 'connections.acceptRequestByUserIdAndType',
  authed ConnectionCtrl.acceptRequestByUserIdAndType
.on 'connections.upsertByUserIdAndType',
  authed ConnectionCtrl.upsertByUserIdAndType
.on 'connections.deleteByUserIdAndType',
  authed ConnectionCtrl.deleteByUserIdAndType

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

# .on 'coordinates.search', authed CoordinateCtrl.search
.on 'coordinates.upsert', authed CoordinateCtrl.upsert

.on 'geocoder.autocomplete', authed GeocoderCtrl.autocomplete
.on 'geocoder.getBoundingFromRegion', authed GeocoderCtrl.getBoundingFromRegion
.on 'geocoder.getBoundingFromLocation',
  authed GeocoderCtrl.getBoundingFromLocation
.on 'geocoder.getElevationFromLocation',
  authed GeocoderCtrl.getElevationFromLocation

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
.on 'groupUsers.getByGroupIdAndUserId',
  authed GroupUserCtrl.getByGroupIdAndUserId
.on 'groupUsers.getTopByGroupId', authed GroupUserCtrl.getTopByGroupId
# .on 'groupUsers.getMeSettingsByGroupId',
#   authed GroupUserCtrl.getMeSettingsByGroupId
# .on 'groupUsers.updateMeSettingsByGroupId',
#   authed GroupUserCtrl.updateMeSettingsByGroupId
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

.on 'overnights.deleteByRow', authed OvernightCtrl.deleteByRow
.on 'overnights.getBySlug', authed OvernightCtrl.getBySlug
.on 'overnights.getNearestAmenitiesById',
  authed OvernightCtrl.getNearestAmenitiesById
.on 'overnights.search', authed OvernightCtrl.search
.on 'overnights.upsert', authed OvernightCtrl.upsert
.on 'overnights.getIsAllowedByMeAndId',
  authed OvernightCtrl.getIsAllowedByMeAndId
.on 'overnights.markIsAllowedById', authed OvernightCtrl.markIsAllowedById

.on 'overnightReviews.getById', authed OvernightReviewCtrl.getById
.on 'overnightReviews.deleteById', authed OvernightReviewCtrl.deleteById
.on 'overnightReviews.getAllByParentId',
  authed OvernightReviewCtrl.getAllByParentId
.on 'overnightReviews.search', authed OvernightReviewCtrl.search
.on 'overnightReviews.upsert', authed OvernightReviewCtrl.upsert
.on 'overnightReviews.uploadImage', authed OvernightReviewCtrl.uploadImage

.on 'overnightAttachments.getAllByParentId',
  authed OvernightAttachmentCtrl.getAllByParentId
.on 'overnightAttachments.deleteByRow',
  authed OvernightAttachmentCtrl.deleteByRow

.on 'placeAttachments.getAllByUserId', authed PlaceAttachmentCtrl.getAllByUserId

.on 'placeReviews.getAllByUserId', authed PlaceReviewCtrl.getAllByUserId
.on 'placeReviews.getCountByUserId', authed PlaceReviewCtrl.getCountByUserId

.on 'notifications.getAll', authed NotificationCtrl.getAll
.on 'notifications.getUnreadCount', authed NotificationCtrl.getUnreadCount

.on 'nps.create', authed NpsCtrl.create

.on 'products.getBySlug', authed ProductCtrl.getBySlug
.on 'products.getAllByItemSlug', authed ProductCtrl.getAllByItemSlug

.on 'pushTokens.upsert', authed PushTokenCtrl.upsert

.on 'subscriptions.subscribe', authed SubscriptionCtrl.subscribe
.on 'subscriptions.unsubscribe', authed SubscriptionCtrl.unsubscribe
.on 'subscriptions.getAllByGroupId', authed SubscriptionCtrl.getAllByGroupId
.on 'subscriptions.sync', authed SubscriptionCtrl.sync

.on 'threads.upsert', authed ThreadCtrl.upsert
.on 'threads.getAll', authed ThreadCtrl.getAll
.on 'threads.getById', authed ThreadCtrl.getById
.on 'threads.getBySlug', authed ThreadCtrl.getBySlug
.on 'threads.voteById', authed ThreadCtrl.voteById
.on 'threads.pinById', authed ThreadCtrl.pinById
.on 'threads.unpinById', authed ThreadCtrl.unpinById
.on 'threads.deleteById', authed ThreadCtrl.deleteById
.on 'threads.uploadImage', authed ThreadCtrl.uploadImage

.on 'time.get', authed -> {now: new Date()}

.on 'trips.getAll', authed TripCtrl.getAll
.on 'trips.getById', authed TripCtrl.getById
.on 'trips.getByType', authed TripCtrl.getByType
.on 'trips.getByUserIdAndType', authed TripCtrl.getByUserIdAndType
.on 'trips.getRoute', authed TripCtrl.getRoute
.on 'trips.getStats', authed TripCtrl.getStats
.on 'trips.getStatesGeoJson', authed TripCtrl.getStatesGeoJson
.on 'trips.uploadImage', authed TripCtrl.uploadImage
.on 'trips.upsert', authed TripCtrl.upsert

.on 'users.getMe', authed UserCtrl.getMe
.on 'users.getById', authed UserCtrl.getById
.on 'users.getByUsername', authed UserCtrl.getByUsername
.on 'users.getCountry', authed UserCtrl.getCountry
.on 'users.search', authed UserCtrl.search
.on 'users.setAvatarImage', authed UserCtrl.setAvatarImage
.on 'users.setPartner', authed UserCtrl.setPartner
.on 'users.getPartner', authed UserCtrl.getPartner
.on 'users.upsert', authed UserCtrl.upsert

.on 'userBlocks.getAll', authed UserBlockCtrl.getAll
.on 'userBlocks.getAllIds', authed UserBlockCtrl.getAllIds
.on 'userBlocks.blockByUserId', authed UserBlockCtrl.blockByUserId
.on 'userBlocks.unblockByUserId', authed UserBlockCtrl.unblockByUserId

.on 'userSettings.getByMe', authed UserSettingsCtrl.getByMe
.on 'userSettings.upsert', authed UserSettingsCtrl.upsert

.on 'userLocations.getByMe', authed UserLocationCtrl.getByMe
.on 'userLocations.deleteByMe', authed UserLocationCtrl.deleteByMe
.on 'userLocations.search', authed UserLocationCtrl.search

.on 'userRigs.getByMe', authed UserRigCtrl.getByMe
.on 'userRigs.upsert', authed UserRigCtrl.upsert

.on 'votes.upsertByParent',
  authed VoteCtrl.upsertByParent
