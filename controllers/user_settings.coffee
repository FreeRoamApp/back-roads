Promise = require 'bluebird'
_ = require 'lodash'

UserSettings = require '../models/user_settings'

class UserSettingsCtrl
  getByMe: ({}, {user}) ->
    UserSettings.getByUserId user.id

  upsert: (diff, {user}) ->
    diff = _.pick diff, ['privacy']
    diff.privacy = _.pick diff.privacy, ['location']
    console.log 'upsert', diff
    diff = _.defaults {userId: user.id}, diff
    UserSettings.upsert diff

module.exports = new UserSettingsCtrl()
