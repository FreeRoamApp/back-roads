_ = require 'lodash'

uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
User = require './user'
CacheService = require '../services/cache'
config = require '../config'

# with this structure we'd need another table to get votes by parentId

class VoteModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'votes_by_userId'
        keyspace: 'free_roam'
        fields:
          userId: 'uuid'
          topId: 'uuid' # eg threadId
          topType: 'text' # threadId, campgroundReview, ...
          parentType: 'text' # thread, comment
          parentId: 'uuid'
          vote: 'int'
          time: 'timestamp'
        primaryKey:
          partitionKey: ['userId', 'topId']
          clusteringColumns: ['parentType', 'parentId']
      }
    ]

  getByUserIdAndParent: (userId, parent) ->
    console.log 'get vote', parent
    cknex().select '*'
    .from 'votes_by_userId'
    .where 'userId', '=', userId
    .andWhere 'parentType', '=', parent.type
    .andWhere 'topId', '=', parent.topId or config.EMPTY_UUID
    .andWhere 'parentId', '=', parent.id
    .run {isSingle: true}

  getAllByUserIdAndTopIdAndParentType: (userId, topId, parentType) ->
    cknex().select '*'
    .from 'votes_by_userId'
    .where 'userId', '=', userId
    .andWhere 'topId', '=', topId
    .andWhere 'parentType', '=', parentType
    .run()

  getAllByUserIdAndParents: (userId, parents) ->
    cknex().select '*'
    .from 'votes_by_userId'
    .where 'userId', '=', userId
    .andWhere 'topId', '=', parents[0].topId or config.EMPTY_UUID
    .andWhere 'parentType', '=', parents[0].type
    .andWhere 'parentId', 'in', _.map(parents, 'id')
    .run()

  defaultInput: (vote) ->
    unless vote?
      return null

    _.defaults vote, {
      topId: config.EMPTY_UUID
      vote: 0 # -1 or 1
      time: new Date()
    }

module.exports = new VoteModel()
