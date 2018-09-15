Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
CampgroundReview = require '../models/campground_review'
ReviewBaseCtrl = require './review_base'

class CampgroundReviewCtrl extends ReviewBaseCtrl
  type: 'campgroundReview'
  imageFolder: 'rvcg'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: CampgroundReview

module.exports = new CampgroundReviewCtrl()
