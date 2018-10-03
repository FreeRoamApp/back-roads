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

  upsertExtras: ->
    null

module.exports = new CampgroundReviewCtrl()
