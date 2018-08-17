_ = require 'lodash'

GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
User = require '../models/user'

class GroupUserEmbed
  roles: (groupUser) ->
    GroupRole.getAllByGroupUuid(
      groupUser.groupUuid, {preferCache: true}
    ).then (roles) ->
      everyoneRole = _.find roles, {name: 'everyone'}
      groupUserRoles = _.filter _.map groupUser.roleUuids, (roleUuid) ->
        _.find roles, (role) ->
          "#{role.roleUuid}" is "#{roleUuid}"
      if everyoneRole
        groupUserRoles = groupUserRoles.concat everyoneRole

  roleNames: (groupUser) ->
    GroupRole.getAllByGroupUuid(
      groupUser.groupUuid, {preferCache: true}
    ).then (roles) ->
      groupUserRoleNames = _.filter _.map groupUser.roleUuids, (roleUuid) ->
        _.find(roles, (role) ->
          "#{role.roleUuid}" is "#{roleUuid}")?.name
      groupUserRoleNames = groupUserRoleNames.concat 'everyone'

  karma: (groupUser) ->
    return Promise.resolve 0 # TODO

    if groupUser.userUuid
      GroupUser.getKarmaByGroupUuidAndUserUuid(
        groupUser.groupUuid, groupUser.userUuid
      )

  user: (groupUser) ->
    if groupUser.userUuid
      User.getByUuid groupUser.userUuid
      .then User.sanitizePublic(null)


module.exports = new GroupUserEmbed()
