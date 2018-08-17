_ = require 'lodash'

GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
User = require '../models/user'

class GroupUserEmbed
  roles: (groupUser) ->
    GroupRole.getAllByGroupId(
      groupUser.groupId, {preferCache: true}
    ).then (roles) ->
      everyoneRole = _.find roles, {name: 'everyone'}
      groupUserRoles = _.filter _.map groupUser.roleIds, (roleId) ->
        _.find roles, (role) ->
          "#{role.roleId}" is "#{roleId}"
      if everyoneRole
        groupUserRoles = groupUserRoles.concat everyoneRole

  roleNames: (groupUser) ->
    GroupRole.getAllByGroupId(
      groupUser.groupId, {preferCache: true}
    ).then (roles) ->
      groupUserRoleNames = _.filter _.map groupUser.roleIds, (roleId) ->
        _.find(roles, (role) ->
          "#{role.roleId}" is "#{roleId}")?.name
      groupUserRoleNames = groupUserRoleNames.concat 'everyone'

  karma: (groupUser) ->
    return Promise.resolve 0 # TODO

    if groupUser.userId
      GroupUser.getKarmaByGroupIdAndUserId(
        groupUser.groupId, groupUser.userId
      )

  user: (groupUser) ->
    if groupUser.userId
      User.getById groupUser.userId
      .then User.sanitizePublic(null)


module.exports = new GroupUserEmbed()
