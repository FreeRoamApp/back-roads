Promise = require 'bluebird'
_ = require 'lodash'

UserRig = require '../models/user_rig'

class UserRigCtrl
  getByMe: ({}, {user}) ->
    UserRig.getByUserId user.id

  upsert: (diff, {user}) ->
    diff = _.pick diff, ['type', 'length', 'is4x4']
    if diff.length
      diff.length = "#{parseInt(diff.length)}"
    diff.userId = user.id
    UserRig.upsert diff

module.exports = new UserRigCtrl()
