Promise = require 'bluebird'
moment = require 'moment'

Base = require './base'
cknex = require '../services/cknex'

class GiveawayEntry extends Base
  getScyllaTables: ->
    [
      {
        name: 'giveaway_entries'
        keyspace: 'free_roam'
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          timeBucket: {type: 'text', defaultFn: -> 'WEEK-' + moment().format 'GGGG-WW'}
          action: 'text'
        primaryKey:
          partitionKey: ['timeBucket']
          clusteringColumns: ['userId', 'id']
      }
    ]

  getAllByTimeBucket: (timeBucket) =>
    cknex().select '*'
    .from 'giveaway_entries'
    .where 'timeBucket', '=', timeBucket
    .run()
    .map @defaultOutput

  getAllByTimeBucketAndUserId: (timeBucket, userId) ->
    cknex().select '*'
    .from 'giveaway_entries'
    .where 'timeBucket', '=', timeBucket
    .andWhere 'userId', '=', userId
    .run()
    .map @defaultOutput

module.exports = new GiveawayEntry()
