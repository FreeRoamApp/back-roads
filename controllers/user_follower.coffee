_ = require 'lodash'
router = require 'exoid-router'

UserFollower = require '../models/user_follower'
User = require '../models/user'
EmbedService = require '../services/embed'
PushNotificationService = require '../services/push_notification'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.USER_FOLLOWER.USER]
followedEmbed = [EmbedService.TYPES.USER_FOLLOWER.FOLLOWED]

class UserFollowerCtrl
  getAllFollowingIds: ({userId, embed}, {user}) ->
    userId ?= user.id
    UserFollower.getAllFollowingByUserId userId
    .map (userFollower) ->
      userFollower.followedId

  getAllFollowerIds: ({userId, embed}, {user}) ->
    userId ?= user.id
    UserFollower.getAllFollowersByUserId userId
    .map (userFollower) ->
      userFollower.userId

  getAllFollowing: ({userId, embed}, {user}) ->
    userId ?= user.id
    UserFollower.getAllFollowingByUserId userId
    .map EmbedService.embed {embed: followedEmbed}

  getAllFollowers: ({userId, embed}, {user}) ->
    userId ?= user.id
    UserFollower.getAllFollowersByUserId userId
    .map EmbedService.embed {embed: defaultEmbed}

  followByUserId: ({userId}, {user}) ->
    followedId = userId
    UserFollower.getByUserIdAndFollowedId user.id, followedId
    .then (userFollower) ->
      unless userFollower
        UserFollower.upsert {userId: user.id, followedId: followedId}
    .then ->
      User.getById followedId
      .then (otherUser) ->
        PushNotificationService.send otherUser, {
          titleObj:
            key: 'newFollower.title'
          type: PushNotificationService.TYPES.NEW_FRIEND
          # url: "https://#{config.SUPERNOVA_HOST}"
          textObj:
            key: 'newFollower.text'
            replacements:
              name: User.getDisplayName(user)
          data:
            path:
              key: 'people'
        }
      .catch -> null
      null

  unfollowByUserId: ({userId}, {user}) ->
    followedId = userId
    UserFollower.deleteByUserIdAndFollowedId user.id, followedId


module.exports = new UserFollowerCtrl()
