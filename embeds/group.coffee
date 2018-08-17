_ = require 'lodash'

GroupUser = require '../models/group_user'
User = require '../models/user'

class GroupEmbed
  userCount: (group) ->
    if group.type isnt 'public' and group.userIds?.then
      group.userIds.then (userIds) ->
        userIds.length
    else if group.type isnt 'public' and group.userIds
      group.userIds.length
    else
      GroupUser.getCountByGroupId group.id, {
        preferCache: true
      }

  users: (group) ->
    Promise.map group.userIds, (userId) ->
      User.getById userId, {preferCache: true}
    .map embedFn {embed: [TYPES.USER.IS_ONLINE]}
    .map User.sanitizePublic null

module.exports = new GroupEmbed()
