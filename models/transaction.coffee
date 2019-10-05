_ = require 'lodash'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'

scyllaFields =
  id: 'timeuuid'
  userId: 'uuid'
  amountCents: {type: 'int', defaultFn: -> 0}
  isSuccess: {type: 'boolean', defaultFn: -> false}
  orderId: 'text'
  isActiveSubscription: 'boolean'
  subscriptionInterval: 'text' # '', 'month'

class TransactionModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'transactions_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
      }
      {
        name: 'transactions_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
          clusteringColumns: null
      }
      {
        name: 'transactions_by_orderId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['orderId']
          clusteringColumns: ['id']
      }
    ]

  getById: (id) =>
    cknex().select '*'
    .from 'transactions_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getAllByOrderId: (orderId) =>
    cknex().select '*'
    .from 'transactions_by_orderId'
    .where 'orderId', '=', orderId
    .run()
    .map @defaultOutput


  getAllByUserId: (userId) =>
    cknex().select '*'
    .from 'transactions_by_userId'
    .where 'userId', '=', userId
    .run()
    .map @defaultOutput

  defaultOutput: (transaction) ->
    transaction = super transaction
    if transaction?.id
      transaction.time = cknex.getDateFromTimeUuid transaction.id
    transaction

module.exports = new TransactionModel()
