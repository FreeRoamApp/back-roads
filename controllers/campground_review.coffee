Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
PlaceReviewService = require '../services/place_review'
CampgroundAttachment = require '../models/campground_attachment'
CampgroundReview = require '../models/campground_review'
Campground = require '../models/campground'
PlaceReviewBaseCtrl = require './place_review_base'

class CampgroundReviewCtrl extends PlaceReviewBaseCtrl
  type: 'campgroundReview'
  parentType: 'campground'
  imageFolder: 'rvcg'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: CampgroundReview
  ParentModel: Campground
  AttachmentModel: CampgroundAttachment

module.exports = new CampgroundReviewCtrl()
