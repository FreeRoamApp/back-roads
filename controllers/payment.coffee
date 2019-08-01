_ = require 'lodash'
Promise = require 'bluebird'
stripe = require 'stripe'
router = require 'exoid-router'
moment = require 'moment'

User = require '../models/user'
UserPrivateData = require '../models/user_private_data'
Transaction = require '../models/transaction'
EmailService = require '../services/email'
config = require '../config'

ONE_DAY_MS = 3600 * 24 * 1000

stripe = stripe(config.STRIPE_SECRET_KEY)

completeVerifiedPurchase = (user, options) ->
  {platform, revenueCents, transactionId} = options
  # do something?

class PaymentCtrl
  _charge: ({amountCents, customerId}) ->
    stripe.charges.create {
      amount: amountCents
      currency: 'usd'
      customer: customerId
      # metadata: {
      #   orderId: '' # TODO
      # }
    }

  _subscribe: ({amountCents, subscriptionInterval, customerId}) ->
    dollarAmount = Math.round(100 * amountCents / 100) / 100
    console.log 'sub'
    stripe.plans.retrieve "#{amountCents}usdCents"
    .catch -> null # no such plan
    .then (plan) ->
      console.log 'plan', plan
      if plan
        return plan
      else
        stripe.plans.create {
          id: "#{amountCents}usdCents"
          amount: amountCents
          interval: subscriptionInterval
          product: {
            name: "$#{dollarAmount} monthly"
          },
          currency: 'usd'
        }
    .then ->
      stripe.subscriptions.create {
        customer: customerId
        items: [
          {
            plan: "#{amountCents}usdCents"
          }
        ]
      }

  _getCustomer: ({stripeToken, userId, stripeCustomerId}) ->
    if stripeToken
      stripe.customers.create({
        source: stripeToken,
        description: userId
      })
    else if stripeCustomerId
      Promise.resolve {id: stripeCustomerId}

  purchase: (options, {user}) =>
    {stripeToken, transactionId, platform, amount,
      subscriptionInterval} = options

    console.log 'purch', options

    amount = parseInt(amount)
    amountCents = amount * 100
    if isNaN amountCents
      router.throw {
        info: 'Invalid amount'
        status: 400
      }

    if amountCents > 50000
      router.throw {
        info: 'If you want to donate more than $500, send us an email first :) austin@freeroam.app'
        status: 400
      }

    transaction = {}

    Promise.all [
      UserPrivateData.getByUserId user.id
    ]
    .then ([userPrivateData]) =>
      transaction =
        userId: user.id
        amountCents: amountCents
        id: transactionId
        isActiveSubscription: Boolean subscriptionInterval
        subscriptionInterval: subscriptionInterval

      @_getCustomer {
        stripeToken
        userId: user.id
        stripeCustomerId: userPrivateData?.data?.stripeCustomerId
      }
      .then (customer) =>
        unless customer
          router.throw
            status: 400
            info: 'No token'

        (if subscriptionInterval is 'month'
          @_subscribe {
            amountCents, subscriptionInterval, customerId: customer.id
          }
        else
          @_charge {amountCents, customerId: customer.id}
        )
        .catch (err) ->
          console.log err
          Transaction.upsert transaction
          router.throw
            status: 400
            info: 'Unable to verify payment'

        .then (response) =>
          Promise.all [
            User.upsertByRow user, {
              flags: _.defaults {
                hasStripeId: true
                isSupporter: true
              }, user.flags
            }

            UserPrivateData.upsert {
              userId: user.id
              data:
                stripeCustomerId: customer.id
            }
          ]
          .then ->
            completeVerifiedPurchase user, {
              platform
              id: transactionId
              revenueCents: amountCents
            }
          .then =>
            transaction.isSuccess = true
            transaction.orderId = response.id

            @_sendEmail {user, amount, subscriptionInterval}

            Transaction.upsert transaction

      .catch (err) ->
        console.log err
        Transaction.upsert transaction
        router.throw
          status: 400
          info: 'Payment succeeded, but there was an error after. Please email austin@freeroam.app'

  _sendEmail: ({user, amount, subscriptionInterval}) ->
    name = User.getDisplayName user
    time = moment().format 'LLL'
    frequency = if subscriptionInterval is 'month' \
                then 'Monthly'
                else if subscriptionInterval
                then subscriptionInterval
                else 'One-time'
    EmailService.send {
      to: user.email
      subject: "FreeRoam Donation Receipt"
      text: """
Hi #{name}, thank you so much for donating to FreeRoam! Your donation helps a lot toward our mission of helping connect campers with nature in a respectful, sustainable way.

This email can serve as a receipt for your donation.

Donation amount: $#{amount}
Donation frequency: #{frequency}
Time: #{time}

FreeRoam Foundation is a registered 501(c)3 non-profit with tax ID: 83-2974909. No goods or services were provided by FreeRoam in return for this contribution.
"""
    }

  resetStripeInfo: ({}, {user}) ->
    Promise.all [
      User.upsertByRow user, {
        flags:
          _.defaults {hasStripeId: false}, user.flags
      }
      UserPrivateData.upsert {
        userId: user.id
        data:
          stripeCustomerId: null
      }
    ]

  stripe: (req, res) -> # stripe webhook
    sig = req.headers['stripe-signature']
    try
      event = stripe.webhooks.constructEvent req.body, sig, config.STRIPE_SIGNING_SECRET
    catch err
      res.status(400).send err.message

    if event.type is 'invoice.payment_succeeded'
      object = event.data.object
      Transaction.getAllByOrderId object.subscription
      .then (transactions) ->
        unless transactions?[0]
          return res.status(200).send('no txn found')
        delete transactions[0].id
        Transaction.upsert _.defaults {
          amountCents: object.amount_paid
        }, transactions[0]
      .then ->
        res.status(200).send('success')
    else
      res.status(200).send()

module.exports = new PaymentCtrl()
