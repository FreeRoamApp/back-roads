_ = require 'lodash'

uuid = require 'node-uuid'

cknex = require '../services/cknex'
User = require './user'
CacheService = require '../services/cache'

DEFAULT_UUID = '00000000-0000-0000-0000-000000000000'

defaultThreadVote = (threadVote) ->
  unless threadVote?
    return null

  _.defaults threadVote, {
    vote: 0 # -1 or 1
    time: new Date()
  }

# with this structure we'd need another table to get votes by parentUuid
tables = [
  {
    name: 'thread_votes_by_userUuid'
    keyspace: 'free_roam'
    fields:
      userUuid: 'uuid'
      parentTopUuid: 'uuid' # eg threadUuid for threadComments
      parentType: 'text'
      parentUuid: 'uuid'
      vote: 'int'
      time: 'timestamp'
    primaryKey:
      # a little uneven since some users will vote a lot, but small data overall
      partitionKey: ['userUuid', 'parentTopUuid', 'parentType']
      clusteringColumns: ['parentUuid']
  }
]

class ThreadVoteModel
  SCYLLA_TABLES: tables

  upsertByUserUuidAndParent: (userUuid, parent, threadVote) ->
    threadVote = defaultThreadVote threadVote

    cknex().update 'thread_votes_by_userUuid'
    .set threadVote
    .where 'userUuid', '=', userUuid
    .andWhere 'parentTopUuid', '=', parent.topUuid or DEFAULT_UUID
    .andWhere 'parentType', '=', parent.type
    .andWhere 'parentUuid', '=', parent.uuid
    .run()
    .then ->
      threadVote

  getByUserUuidAndParent: (userUuid, parent) ->
    cknex().select '*'
    .from 'thread_votes_by_userUuid'
    .where 'userUuid', '=', userUuid
    .andWhere 'parentType', '=', parent.type
    .andWhere 'parentTopUuid', '=', parent.topUuid or DEFAULT_UUID
    .andWhere 'parentUuid', '=', parent.uuid
    .run {isSingle: true}

  getAllByUserUuidAndParentTopUuid: (userUuid, parentTopUuid) ->
    cknex().select '*'
    .from 'thread_votes_by_userUuid'
    .where 'userUuid', '=', userUuid
    .where 'parentTopUuid', '=', parentTopUuid
    .where 'parentType', '=', 'threadComment'
    .run()

  getAllByUserUuidAndParents: (userUuid, parents) ->
    cknex().select '*'
    .from 'thread_votes_by_userUuid'
    .where 'userUuid', '=', userUuid
    .andWhere 'parentTopUuid', '=', parents[0].topUuid or DEFAULT_UUID
    .andWhere 'parentType', '=', parents[0].type
    .andWhere 'parentUuid', 'in', _.map(parents, 'uuid')
    .run()


module.exports = new ThreadVoteModel()
