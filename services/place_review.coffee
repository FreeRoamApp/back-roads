_ = require 'lodash'


class PlaceReviewService
  getParentDiffFromExtras: ({parent, extras, operator}) ->
    operator ?= 'add'
    multiplier = if operator is 'add' then 1 else -1
    _.reduce extras, (diff, addValue, key) ->
      if key is 'userId'
        return
      valueKey = if key is 'cellSignal' then 'signal' else 'value'
      if typeof addValue is 'object' # seasonal, cell, day/night
        diff[key] = parent[key] or {}
        _.forEach addValue, (subAddValue, subKey) ->
          value = parent[key]?[subKey]?[valueKey] or 0
          count = parent[key]?[subKey]?.count or 0
          newCount = count + (1 * multiplier)
          if newCount is 0
            newValue = 0
          else
            newValue = (value * count + (subAddValue * multiplier)) / newCount
            newValue = Math.round(newValue * 10000) / 10000 # x.xxxx
          diff[key] = _.defaults {
            "#{subKey}":
              "#{valueKey}": newValue
              count: newCount
          }, diff[key]
      else if addValue
        value = parent[key]?[valueKey] or 0
        count = parent[key]?.count or 0
        newCount = count + (1 * multiplier)
        if newCount is 0
          newValue = 0
        else
          newValue = (value * count + (addValue * multiplier)) / newCount
          newValue = Math.round(newValue * 10000) / 10000 # x.xxxx
        diff[key] = _.defaults {
          "#{valueKey}": newValue
          count: newCount
        }
      diff
    , {}

  getParentDiff: (parent, rating, {existingReview, userRig} = {}) ->
    totalStars = (parent.rating or 0) * (parent.ratingCount or 0)
    if existingReview
      totalStars or= existingReview.rating
      totalStars -= existingReview.rating
      totalStars += rating
      newRatingCount = parent.ratingCount
    else
      totalStars += rating
      newRatingCount = parent.ratingCount + 1
    newRating = totalStars / newRatingCount

    parentUpsert = {
      rating: newRating, ratingCount: newRatingCount
    }

    # update maxLength and allowedTypes if we can
    if rating > 3 and userRig
      # TODO: problem with this is it's more of a maxReportedLength
      maxLength = parent.maxLength or 0
      if userRig.length > maxLength and userRig.length < 60
        parentUpsert.maxLength = userRig.length

      allowedTypes = parent.allowedTypes or {}
      if userRig.type and not allowedTypes[userRig.type]
        parentUpsert.allowedTypes = _.defaults {
          "#{userRig.type}": true
        }, allowedTypes

    parentUpsert


module.exports = new PlaceReviewService()
