Promise = require 'bluebird'
_ = require 'lodash'

UserData = require '../models/user_data'

class UserDataCtrl
  getByMe: ({}, {user}) ->
    UserData.getByUserId user.id

  getByUserId: ({userId}, {user}) ->
    UserData.getByUserId userId

  upsert: (diff, {user}) ->
    console.log 'diff', diff
    diff = _.pick diff, ['bio', 'occupation', 'home', 'startTime']
    diff.userId = user.id
    UserData.upsert diff

module.exports = new UserDataCtrl()
