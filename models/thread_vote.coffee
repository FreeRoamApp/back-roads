_ = require 'lodash'

uuid = require 'node-uuid'

cknex = require '../services/cknex'
User = require './user'
CacheService = require '../services/cache'

DEFAULT_ID = '00000000-0000-0000-0000-000000000000'

defaultThreadVote = (threadVote) ->
  unless threadVote?
    return null

  _.defaults threadVote, {
    vote: 0 # -1 or 1
    time: new Date()
  }

# with this structure we'd need another table to get votes by parentId
tables = [
  {
    name: 'thread_votes_by_userId'
    keyspace: 'free_roam'
    fields:
      userId: 'uuid'
      parentTopId: 'uuid' # eg threadId for threadComments
      parentType: 'text'
      parentId: 'uuid'
      vote: 'int'
      time: 'timestamp'
    primaryKey:
      # a little uneven since some users will vote a lot, but small data overall
      partitionKey: ['userId', 'parentTopId', 'parentType']
      clusteringColumns: ['parentId']
  }
]

class ThreadVoteModel
  SCYLLA_TABLES: tables

  upsertByUserIdAndParent: (userId, parent, threadVote) ->
    threadVote = defaultThreadVote threadVote

    cknex().update 'thread_votes_by_userId'
    .set threadVote
    .where 'userId', '=', userId
    .andWhere 'parentTopId', '=', parent.topId or DEFAULT_ID
    .andWhere 'parentType', '=', parent.type
    .andWhere 'parentId', '=', parent.id
    .run()
    .then ->
      threadVote

  getByUserIdAndParent: (userId, parent) ->
    cknex().select '*'
    .from 'thread_votes_by_userId'
    .where 'userId', '=', userId
    .andWhere 'parentType', '=', parent.type
    .andWhere 'parentTopId', '=', parent.topId or DEFAULT_ID
    .andWhere 'parentId', '=', parent.id
    .run {isSingle: true}

  getAllByUserIdAndParentTopId: (userId, parentTopId) ->
    cknex().select '*'
    .from 'thread_votes_by_userId'
    .where 'userId', '=', userId
    .where 'parentTopId', '=', parentTopId
    .where 'parentType', '=', 'threadComment'
    .run()

  getAllByUserIdAndParents: (userId, parents) ->
    cknex().select '*'
    .from 'thread_votes_by_userId'
    .where 'userId', '=', userId
    .andWhere 'parentTopId', '=', parents[0].topId or DEFAULT_ID
    .andWhere 'parentType', '=', parents[0].type
    .andWhere 'parentId', 'in', _.map(parents, 'id')
    .run()


module.exports = new ThreadVoteModel()
