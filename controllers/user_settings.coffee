Promise = require 'bluebird'
_ = require 'lodash'

UserLocation = require '../models/user_location'
UserSettings = require '../models/user_settings'

class UserSettingsCtrl
  getByMe: ({}, {user}) ->
    UserSettings.getByUserId user.id

  upsert: (diff, {user}) ->
    diff = _.pick diff, ['privacy']
    diff.privacy = _.pick diff.privacy, ['location']
    diff = _.defaults {userId: user.id}, diff
    Promise.all _.filter [
      UserSettings.upsert diff
      if diff.privacy?.location and not diff.privacy?.location.everyone
        UserLocation.getByUserId user.id
        .then (userLocation) ->
          UserLocation.upsertByRow userLocation, {
            privacy: 'private'
          }
    ]

module.exports = new UserSettingsCtrl()
