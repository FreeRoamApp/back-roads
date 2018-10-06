Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
CampgroundAttachment = require '../models/campground_attachment'
CampgroundReview = require '../models/campground_review'
Campground = require '../models/campground'
ReviewBaseCtrl = require './review_base'

class CampgroundReviewCtrl extends ReviewBaseCtrl
  type: 'campgroundReview'
  imageFolder: 'rvcg'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: CampgroundReview
  ParentModel: Campground
  AttachmentModel: CampgroundAttachment

  upsertExtras: ({id, parent, extras}, {user}) =>
    extras = _.pick extras, [
      'roadDifficulty', 'crowds', 'fullness', 'noise',
      'shade', 'safety', 'cellSignal'
    ]

    # TODO allow specifying day/night noise
    if extras.noise
      extras.noise = {day: extras.noise, night: extras.noise}

    # update averages
    parentDiff = _.reduce extras, (diff, addValue, key) ->
      valueKey = if key is 'cellSignal' then 'signal' else 'value'
      if typeof addValue is 'object' # seasonal, cell, day/night
        diff[key] = parent[key] or {}
        _.forEach addValue, (subAddValue, subKey) ->
          value = parent[key]?[subKey]?[valueKey] or 0
          count = parent[key]?[subKey]?.count or 0
          newValue = (value * count + subAddValue) / (count + 1)
          newValue = Math.round(newValue * 10000) / 10000 # x.xxxx
          diff[key] = _.defaults {
            "#{subKey}":
              "#{valueKey}": newValue
              count: count + 1
          }, diff[key]
      else if addValue
        value = parent[key]?[valueKey] or 0
        count = parent[key]?.count or 0
        newValue = (value * count + addValue) / (count + 1)
        newValue = Math.round(newValue * 10000) / 10000 # x.xxxx
        diff[key] = _.defaults {"#{valueKey}": newValue, count: count + 1}
      diff
    , {}

    @ParentModel.upsert _.defaults {
      id: parent.id, slug: parent.slug
    }, parentDiff

    if id # id isnt there if just updating the parent w/o review
      CampgroundReview.upsertExtras _.defaults {id, userId: user.id}, extras

module.exports = new CampgroundReviewCtrl()
