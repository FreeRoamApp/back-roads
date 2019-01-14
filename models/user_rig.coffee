_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
config = require '../config'

class UserRig extends Base
  SCYLLA_TABLES: [
    {
      name: 'user_rigs_by_userId'
      keyspace: 'free_roam'
      fields:
        userId: 'uuid'
        name: 'text'
        # fifthWheel, travelTrailer, van, classA, classB, classC, car, tent
        type: 'text'
        length: 'int'
        is4x4: 'boolean'
      primaryKey:
        partitionKey: ['userId']
    }
  ]

  getByUserId: (userId) =>
    cknex().select '*'
    .from 'user_rigs_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}
    .then @defaultOutput

module.exports = new UserRig()
