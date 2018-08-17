_ = require 'lodash'

GroupUser = require '../models/group_user'
User = require '../models/user'

class GroupEmbed
  userCount: (group) ->
    if group.type isnt 'public' and group.userUuids?.then
      group.userUuids.then (userUuids) ->
        userUuids.length
    else if group.type isnt 'public' and group.userUuids
      group.userUuids.length
    else
      GroupUser.getCountByGroupUuid group.uuid, {
        preferCache: true
      }

  users: (group) ->
    Promise.map group.userUuids, (userUuid) ->
      User.getByUuid userUuid, {preferCache: true}
    .map embedFn {embed: [TYPES.USER.IS_ONLINE]}
    .map User.sanitizePublic null

module.exports = new GroupEmbed()
