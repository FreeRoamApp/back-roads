_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
config = require '../config'

class UserData extends Base
  getScyllaTables: ->
    [
      {
        name: 'user_data_by_userId'
        keyspace: 'free_roam'
        fields:
          userId: 'uuid'
          bio: 'text'
          occupation: 'text'
          home: 'text'
          startTime: 'text'
          # could put links here instead of on user model, but we do want
          # those to show on profileDialog, etc... w/o pulling all data
        primaryKey:
          partitionKey: ['userId']
      }
    ]

  getByUserId: (userId) =>
    cknex().select '*'
    .from 'user_data_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}
    .then @defaultOutput

module.exports = new UserData()
