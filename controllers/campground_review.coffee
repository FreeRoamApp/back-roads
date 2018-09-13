Promise = require 'bluebird'
_ = require 'lodash'

CampgroundReview = require '../models/campground_review'
ReviewBaseCtrl = require './review_base'

class CampgroundReviewCtrl extends ReviewBaseCtrl
  type: 'campgroundReview'
  imageFolder: 'rvcg'
  Model: CampgroundReview

module.exports = new CampgroundReviewCtrl()
