Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
AmenityAttachment = require '../models/amenity_attachment'
AmenityReview = require '../models/amenity_review'
Amenity = require '../models/amenity'
PlaceReviewBaseCtrl = require './place_review_base'

VALID_EXTRAS = [
]

class AmenityReviewCtrl extends PlaceReviewBaseCtrl
  type: 'amenityReview'
  parentType: 'amenity'
  imageFolder: 'rvam'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: AmenityReview
  ParentModel: Amenity
  AttachmentModel: AmenityAttachment

module.exports = new AmenityReviewCtrl()
