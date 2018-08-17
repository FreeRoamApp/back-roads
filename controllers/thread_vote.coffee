_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

Thread = require '../models/thread'
ThreadComment = require '../models/thread_comment'
ThreadVote = require '../models/thread_vote'
config = require '../config'

class ThreadVoteCtrl
  upsertByParent: ({parent, vote}, {user}) ->
    ThreadVote.getByUserIdAndParent user.id, parent
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

      Promise.all [
        ThreadVote.upsertByUserIdAndParent(
          user.id, parent, {vote: voteNumber}
        )

        if parent.type is 'thread'
          Thread.incrementById parent.id, values
        else
          ThreadComment.voteByThreadComment parent, values
      ]

module.exports = new ThreadVoteCtrl()
