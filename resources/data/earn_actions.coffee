# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_WEEK_SECONDS = 3600 * 24 * 7

actions =
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
