Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
CampgroundReview = require '../models/campground_review'
Campground = require '../models/campground'
ReviewBaseCtrl = require './review_base'

class CampgroundReviewCtrl extends ReviewBaseCtrl
  type: 'campgroundReview'
  imageFolder: 'rvcg'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: CampgroundReview
  ParentModel: Campground

module.exports = new CampgroundReviewCtrl()
