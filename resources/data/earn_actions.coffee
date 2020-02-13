# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_WEEK_SECONDS = 3600 * 24 * 7
ONE_YEAR_SECONDS = 3600 * 24 * 365

actions =
  socialPost:
    name: 'Social post'
    data:
      rewards: [
        {currencyAmount: 1, currencyType: 'giveaway_entry'}
      ]
    maxCount: 3
    ttl: ONE_DAY_SECONDS

  # mostly just used to give referrers credit
  firstSocialPost:
    name: 'First social post'
    data:
      rewards: [
        # {currencyAmount: 1, currencyType: 'giveaway_entry'}
      ]
      referrerRewards: [
        {currencyAmount: 5, currencyType: 'giveaway_entry'}
      ]
    maxCount: 1
    ttl: null # infinite

  # TODO: unique / 1 per user they refer, but allow unlimited referrals
  # don't want to do a lot of checks for every social post though...
  # ideally just for user's first post ever
  # referSocialite:
  #   name: 'Referral'
  #   data:
  #     rewards: [
  #       {currencyAmount: 5, currencyType: 'giveaway_entry'}
  #     ]
  #   maxCount: null
  #   ttl: ONE_YEAR_SECONDS

  share:
    name: 'Share FreeRoam'
    data:
      rewards: [
        {currencyAmount: 5, currencyType: 'karma'}
      ]
    maxCount: 1
    ttl: ONE_WEEK_SECONDS

  review:
    name: 'Write a review'
    data:
      rewards: [
        {currencyAmount: 1, currencyType: 'karma'}
      ]
    maxCount: 40
    ttl: ONE_DAY_SECONDS

  reviewUpvoted:
    name: 'Have a review upvoted'
    data:
      rewards: [
        {currencyAmount: 1, currencyType: 'karma'}
      ]
    maxCount: null
    ttl: null

  reviewDownvoted:
    name: 'Have a review downvoted'
    data:
      rewards: [
        {currencyAmount: -1, currencyType: 'karma'}
      ]
    maxCount: null
    ttl: null

  photoUpvoted:
    name: 'Have a photo upvoted'
    data:
      rewards: [
        {currencyAmount: 1, currencyType: 'karma'}
      ]
    maxCount: null
    ttl: null

  photoDownvoted:
    name: 'Have a photo downvoted'
    data:
      rewards: [
        {currencyAmount: -1, currencyType: 'karma'}
      ]
    maxCount: null
    ttl: null


module.exports = _.map actions, (value, action) -> _.defaults {action}, value
