Promise = require 'bluebird'
stripe = require 'stripe'
_ = require 'lodash'

Transaction = require '../models/transaction'
config = require '../config'

stripe = stripe(config.STRIPE_SECRET_KEY)

class TransactionCtrl
  getAll: ({}, {user}) ->
    Transaction.getAllByUserId user.id

  cancelSubscriptionByOrderId: ({orderId}, {user}) ->
    stripe.subscriptions.del(
      orderId
    )
    .then ->
      Transaction.getAllByOrderId orderId
      .map (transaction) ->
        Transaction.upsertByRow transaction, {isActiveSubscription: false}


module.exports = new TransactionCtrl()
