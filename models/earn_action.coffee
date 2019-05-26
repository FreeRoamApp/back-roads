_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

config = require '../config'
Base = require './base'
UserKarma = require './user_karma'
cknex = require '../services/cknex'
TimeService = require '../services/time'
CacheService = require '../services/cache'

ONE_DAY_SECONDS = 3600 * 24
THREE_HOURS_SECONDS = 3600 * 3

defaultEarnTransaction = (earnTransaction) ->
  unless earnTransaction?
    return null

  _.defaults earnTransaction, {
    id: cknex.getTimeUuid()
  }

defaultEarnTransactionLock = (earnTransactionLock) ->
  unless earnTransactionLock?
    return null

  earnTransactionLock

defaultEarnTransactionLockOutput = (earnTransactionLock) ->
  unless earnTransactionLock?
    return null

  earnTransactionLock.count ?= 0
  earnTransactionLock.count = parseInt earnTransactionLock.count
  earnTransactionLock

class EarnActionModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'earn_actions'
        keyspace: 'free_roam'
        fields:
          bucket: {type: 'text', defaultFn: -> 'all'}
          name: 'text'
          action: 'text'
          ttl: 'int'
          data: 'json'
          maxCount: 'int'
        primaryKey:
          partitionKey: ['bucket']
          clusteringColumns: ['action']
      }
      {
        name: 'earn_transaction_locks'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          userId: 'uuid'
          action: 'text'
          count: 'int'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['action']
      }
      {
        name: 'earn_transactions'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          action: 'text'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
      }
    ]

  upsertTransaction: (earnTransaction) =>
    earnTransaction = defaultEarnTransaction earnTransaction
    cknex().update 'earn_transactions'
    .set _.omit earnTransaction, ['userId', 'id']
    .where 'userId', '=', earnTransaction.userId
    .andWhere 'id', '=', earnTransaction.id
    .run()

  upsertTransactionLock: (earnTransaction, {ttl} = {}) ->
    earnTransactionLock = defaultEarnTransactionLock(
      earnTransactionLock
    )

    q = cknex().update 'earn_transaction_locks'
    .set _.omit earnTransaction, [
      'userId', 'action'
    ]
    .where 'userId', '=', earnTransaction.userId
    .andWhere 'action', '=', earnTransaction.action

    if ttl
      q.usingTTL ttl

    q.run()
    .then ->
      earnTransaction

  getAllTransactionLocksByUserId: (userId) ->
    cknex().select 'userId', 'action', 'count'
    .ttl 'count'
    .from 'earn_transaction_locks'
    .where 'userId', '=', userId
    .run()
    .map defaultEarnTransactionLockOutput

  getAll: (groupId) =>
    cknex().select '*'
    .from 'earn_actions'
    .where 'bucket', '=', groupId
    .run()
    .map @defaultOutput

  getByAction: (action) =>
    cknex().select '*'
    .from 'earn_actions'
    .where 'bucket', '=', 'all'
    .andWhere 'action', '=', action
    .run {isSingle: true}
    .then @defaultOutput

  completeActionByUserId: (userId, action) =>
    prefix = CacheService.PREFIXES.EARN_COMPLETE_TRANSACTION
    key = "#{prefix}:#{userId}:#{action}"
    CacheService.lock key, =>
      @getByAction action
      .then (action) =>
        unless action
          throw new Error 'action not found'

        @_checkIfLockedByUserIdAndAction userId, action
        .then ({isLocked, ttl, count}) =>
          if isLocked
            throw new Error 'already claimed'

          Promise.all _.filter [
            Promise.map action.data.rewards, (reward) ->
              if reward.currencyType is 'karma'
                UserKarma.incrementByUserId(
                  userId, reward.currencyAmount
                )
              # else
              #   UserItem.incrementByItemKeyAndUserId(
              #     reward.currencyItemKey, userId, reward.currencyAmount
              #   )
            if action.maxCount
              @upsertTransactionLock {
                userId, action: action.action, count
              }, {ttl}

            @upsertTransaction {userId, action: action.action}
          ]
        .catch (err) ->
          console.log 'err', err
          throw err
        .then ->
          action.data.rewards
    , {expireSeconds: 10, unlockWhenCompleted: true}

  _checkIfLockedByUserIdAndAction: (userId, action) =>
    if action.maxCount
      @getAllTransactionLocksByUserId userId
      .then (transactionsLocks) ->
        existingTransaction = _.find transactionsLocks, {action: action.action}
        return {
          isLocked: existingTransaction?.count >= action.maxCount
          ttl: if existingTransaction \
                then existingTransaction['ttl(count)']
                else action.ttl
          count: (existingTransaction?.count or 0) + 1
        }
    else
      Promise.resolve {isLocked: false}


module.exports = new EarnActionModel()
