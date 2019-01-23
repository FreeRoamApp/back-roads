_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

Comment = require '../models/comment'
Vote = require '../models/vote'
config = require '../config'

Parents =
  comment: require '../models/comment'
  thread: require '../models/thread'
  campgroundReview: require '../models/campground_review'
  overnightReview: require '../models/overnight_review'

class VoteCtrl
  upsertByParent: ({parent, vote}, {user}) ->
    console.log parent
    Vote.getByUserIdAndParent user.id, parent
    .then (existingVote) ->
      voteNumber = if vote is 'up' then 1 else -1

      hasVotedUp = existingVote?.vote is 1
      hasVotedDown = existingVote?.vote is -1
      if existingVote and voteNumber is existingVote.vote
        router.throw status: 400, info: 'already voted'

      if vote is 'up'
        values = {upvotes: 1}
        if hasVotedDown
          values.downvotes = -1
      else if vote is 'down'
        values = {downvotes: 1}
        if hasVotedUp
          values.upvotes = -1

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
