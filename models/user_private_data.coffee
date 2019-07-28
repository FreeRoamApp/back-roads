_ = require 'lodash'

Base = require './base'
cknex = require '../services/cknex'

class UserPrivateDataModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'user_private_data'
        keyspace: 'free_roam'
        fields:
          userId: 'uuid'
          data: 'json'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: null
      }
    ]

  getByUserId: (userId) ->
    cknex().select '*'
    .from 'user_private_data'
    .where 'userId', '=', userId
    .run {isSingle: true}
    .then @defaultOutput


module.exports = new UserPrivateDataModel()
