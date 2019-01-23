Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
CampgroundAttachment = require '../models/campground_attachment'
CampgroundReview = require '../models/campground_review'
Campground = require '../models/campground'
PlaceReviewBaseCtrl = require './place_review_base'

SEASONS = ['winter', 'spring', 'summer', 'fall']
VALID_EXTRAS = [
  'roadDifficulty', 'cleanliness', 'crowds', 'fullness', 'noise',
  'shade', 'safety', 'cellSignal'
]

class CampgroundReviewCtrl extends PlaceReviewBaseCtrl
  type: 'campgroundReview'
  parentType: 'campground'
  imageFolder: 'rvcg'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: CampgroundReview
  ParentModel: Campground
  AttachmentModel: CampgroundAttachment

  getParentDiff: ({parent, extras, operator}) ->
    operator ?= 'add'
    multiplier = if operator is 'add' then 1 else -1
    _.reduce extras, (diff, addValue, key) ->
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

  upsertExtras: ({id, parent, extras, existingReview}, {user}) =>
    # remove old values so we can replace with new
    # doing so updates the averages properly, easily...
    # alternative is calculating what the difference should be (which is
    # the better approach, just harder to code)
    (if existingReview?.extras
      @deleteExtras {id, parent, extras: existingReview.extras}
      .then =>
        @ParentModel.getById parent.id
    else
      Promise.resolve parent
    ).then (parent) =>
      extras = _.pickBy extras, (extra, key) ->
        key in VALID_EXTRAS and (
          typeof extra is 'number' or not _.isEmpty extra
        )

      # TODO allow specifying day/night noise
      if extras.noise
        extras.noise = {day: extras.noise, night: extras.noise}

      # update averages
      parentDiff = @getParentDiff {parent, extras, operator: 'add'}

      # if this campground doesn't have a value for a certain season, set it to
      # whatever value we have, as an estimate
      _.forEach Campground.seasonalFields, (field) ->
        _.forEach SEASONS, (season) ->
          if parentDiff[field] and not parent[season]?.count and
              not parentDiff[field][season]
            value = _.first(_.values(parentDiff[field]))?.value
            if value
              parentDiff[field][season] = {value, count: 0}

      @ParentModel.upsert _.defaults {
        id: parent.id, slug: parent.slug
      }, parentDiff

      if id # id isnt there if just updating the parent w/o review
        CampgroundReview.upsertExtras _.defaults {id, userId: user.id}, extras

  deleteExtras: ({id, parent, extras}) =>
    extras = _.pickBy extras, (extra, key) ->
      key in VALID_EXTRAS and (typeof extra is 'number' or not _.isEmpty extra)

    # update averages
    parentDiff = @getParentDiff {parent, extras, operator: 'sub'}
    Promise.all [
      @ParentModel.upsert _.defaults {
        id: parent.id, slug: parent.slug
      }, parentDiff

      CampgroundReview.deleteExtrasById id
    ]

module.exports = new CampgroundReviewCtrl()
