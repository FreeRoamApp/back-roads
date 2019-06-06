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
          privacy: 'json'
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

module.exports = new UserSettings()
