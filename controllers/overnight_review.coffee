Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
PlaceReviewService = require '../services/place_review'
OvernightAttachment = require '../models/overnight_attachment'
OvernightReview = require '../models/overnight_review'
Overnight = require '../models/overnight'
PlaceReviewBaseCtrl = require './place_review_base'

class OvernightReviewCtrl extends PlaceReviewBaseCtrl
  type: 'overnightReview'
  parentType: 'overnight'
  imageFolder: 'rvov'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: OvernightReview
  ParentModel: Overnight
  AttachmentModel: OvernightAttachment

module.exports = new OvernightReviewCtrl()
