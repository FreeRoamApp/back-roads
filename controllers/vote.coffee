_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

Comment = require '../models/comment'
EarnAction = require '../models/earn_action'
Subscription = require '../models/subscription'
User = require '../models/user'
Vote = require '../models/vote'
PushNotificationService = require '../services/push_notification'
config = require '../config'

Parents =
  comment: require '../models/comment'
  thread: require '../models/thread'
  amenityReview: require '../models/amenity_review'
  campgroundReview: require '../models/campground_review'
  overnightReview: require '../models/overnight_review'

Tops =
  comment: require '../models/comment'
  thread: require '../models/thread'
  amenity: require '../models/amenity'
  campground: require '../models/campground'
  overnight: require '../models/overnight'

class VoteCtrl
  _notifyByParent: (parent, parentRow, user) ->
    console.log parent, parentRow
    Promise.all [
      User.getById parentRow.userId
      if parent.topType
        Tops[parent.topType].getById parent.topId
    ]
    .then ([otherUser, top]) ->
      PushNotificationService.send otherUser, {
        type: Subscription.TYPES.SOCIAL
        titleObj:
          key: "#{parentRow.type}Liked.title"
        textObj:
          key: "#{parentRow.type}Liked.text"
          replacements:
            name: User.getDisplayName(user)
            subject: top?.name or parentRow?.title
        data:
          path:
            if top
              {
                key: "#{top.type}WithTab"
                params:
                  slug: top.slug
                  tab: 'reviews'
              }
            else
              {
                key: parentRow.type
                params:
                  slug: parentRow.slug
              }
      }
  upsertByParent: ({parent, vote}, {user}) =>
    console.log 'parent', parent.type, Parents[parent.type]
    Parents[parent.type].getById parent.id
    .then (parentRow) =>
      unless parentRow
        router.throw status: 400, info: 'parent not found'

      Vote.getByUserIdAndParent user.id, parent
      .then (existingVote) =>
        voteNumber = if vote is 'up' then 1 else -1

        hasVotedUp = existingVote?.vote is 1
        hasVotedDown = existingVote?.vote is -1
        if existingVote and voteNumber is existingVote.vote
          router.throw status: 400, info: 'already voted'

        if vote is 'up'
          values = {upvotes: 1}
          if parent.type in [
            'campgroundReview', 'amenityReview', 'overnightReview'
          ]
            earnAction = 'reviewUpvoted'
          if hasVotedDown
            values.downvotes = -1
        else if vote is 'down'
          values = {downvotes: 1}
          if parent.type in [
            'campgroundReview', 'amenityReview', 'overnightReview'
          ]
            earnAction = 'reviewDownvoted'
          if hasVotedUp
            values.upvotes = -1

        if not existingVote and earnAction? # TODO: handle changing votes (undo action? then do new action)
          EarnAction.completeActionByUserId(
            parentRow.userId
            earnAction
          ).catch -> null

          if vote is 'up'
            @_notifyByParent parent, parentRow, user

        voteTime = existingVote?.time or new Date()

        topType = if parent.topId then parent.topType else parent.type


        Promise.all [
          Vote.upsert {
            userId: user.id
            topId: parent.topId
            topType: topType
            parentType: parent.type
            parentId: parent.id
            vote: voteNumber
          }

          Parents[parent.type].voteByParent parent, values, user.id
        ]

module.exports = new VoteCtrl()
