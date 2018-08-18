_ = require 'lodash'
router = require 'exoid-router'

UserBlock = require '../models/user_block'
User = require '../models/user'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.USER_BLOCK.USER]

class UserBlocksCtrl
  getAll: ({userId}, {user}) ->
    userId ?= user.id
    UserBlock.getAllByUserId userId, {preferCache: true}
    .map EmbedService.embed {embed: defaultEmbed}

  getAllIds: ({userId}, {user}) ->
    userId ?= user.id
    UserBlock.getAllByUserId userId, {preferCache: true}
    .map (userBlock) ->
      userBlock.blockedId

  blockByUserId: ({userId}, {user}) ->
    blockedId = userId
    UserBlock.upsert {userId: user.id, blockedId: blockedId}
      .catch -> null
      # key = "#{CacheService.PREFIXES.USER_DATA_FOLLOWING_PLAYERS}:#{user.id}"
      # CacheService.deleteByKey key
      null

  unblockByUserId: ({userId}, {user}) ->
    blockedId = userId
    UserBlock.deleteByUserIdAndBlockedId user.id, blockedId
    # key = "#{CacheService.PREFIXES.USER_DATA_FOLLOWING}:#{user.id}"
    # CacheService.deleteByKey key
    # null


module.exports = new UserBlocksCtrl()
