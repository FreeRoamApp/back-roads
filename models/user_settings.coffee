_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
config = require '../config'

class UserSettings extends Base
  getScyllaTables: ->
    [
      {
        name: 'user_settings_by_userId'
        keyspace: 'free_roam'
        fields:
          userId: 'uuid'
          privacy: {type: 'text'}
          # location: {everyone: true}
        primaryKey:
          partitionKey: ['userId']
      }
    ]

  getByUserId: (userId) =>
    cknex().select '*'
    .from 'user_settings_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}
    .then @defaultOutput

  defaultInput: (userSettings) ->
    unless userSettings?
      return null

    # transform existing data
    userSettings = _.defaults {
      privacy: JSON.stringify userSettings.privacy
    }, userSettings

    # add data if non-existent
    userSettings = _.defaults userSettings, {
    }

    userSettings

  defaultOutput: (userSettings) ->
    unless userSettings?
      return null

    jsonFields = [
      'privacy'
    ]
    _.forEach jsonFields, (field) ->
      try
        userSettings[field] = JSON.parse userSettings[field]
      catch
        {}

    userSettings

module.exports = new UserSettings()
