_ = require 'lodash'
Promise = require 'bluebird'

GroupUserEmbed = require './group_user'
GroupUser = require '../models/group_user'
User = require '../models/user'
CacheService = require '../services/cache'

FIVE_MINUTES_SECONDS = 60 * 5

class BaseMessageEmbed
  user: ({userId, username, groupId}) ->
    if userId
      key = "#{CacheService.PREFIXES.CHAT_USER}:#{userId}:#{groupId}"
      getFn = User.getById
    else
      key = "#{CacheService.PREFIXES.CHAT_USER_BY_USERNAME}:#{username}:#{groupId}"
      getFn = User.getByUsername

    CacheService.preferCache key, ->
      getFn userId or username, {preferCache: true}
      .then User.sanitizePublic(null)
    , {expireSeconds: FIVE_MINUTES_SECONDS}

  groupUser:  ({userId, groupId}) ->
    prefix = CacheService.PREFIXES.CHAT_GROUP_USER
    key = "#{prefix}:#{groupId}:#{userId}"
    CacheService.preferCache key, ->
      GroupUser.getByGroupIdAndUserId(
        groupId, userId, {preferCache: true}
      )
      .then (groupUser) ->
        Promise.all [
          GroupUserEmbed.roleNames groupUser
        ]
        .then ([roleNames]) ->
          groupUser.roleNames = roleNames
          groupUser
    , {expireSeconds: FIVE_MINUTES_SECONDS}

module.exports = new BaseMessageEmbed()
