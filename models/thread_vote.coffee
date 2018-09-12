_ = require 'lodash'

uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
User = require './user'
CacheService = require '../services/cache'
config = require '../config'

# with this structure we'd need another table to get votes by parentId

class ThreadVoteModel extends Base
  SCYLLA_TABLES: [
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

  getByUserIdAndParent: (userId, parent) ->
    cknex().select '*'
    .from 'thread_votes_by_userId'
    .where 'userId', '=', userId
    .andWhere 'parentType', '=', parent.type
    .andWhere 'parentTopId', '=', parent.topId or config.EMPTY_UUID
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
    .andWhere 'parentTopId', '=', parents[0].topId or config.EMPTY_UUID
    .andWhere 'parentType', '=', parents[0].type
    .andWhere 'parentId', 'in', _.map(parents, 'id')
    .run()

  defaultInput: (threadVote) ->
    unless threadVote?
      return null

    _.defaults threadVote, {
      parentTopId: config.EMPTY_UUID
      vote: 0 # -1 or 1
      time: new Date()
    }

module.exports = new ThreadVoteModel()
