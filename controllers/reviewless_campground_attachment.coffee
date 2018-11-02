Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
ReviewlessCampgroundAttachment = require '../models/reviewless_campground_attachment'
ReviewlessCampground = require '../models/reviewless_campground'
AttachmentBaseCtrl = require './attachment_base'

class ReviewlessCampgroundAttachmentCtrl extends AttachmentBaseCtrl
  type: 'reviewlessCampgroundAttachment'
  defaultEmbed: [
    EmbedService.TYPES.ATTACHMENT.USER, EmbedService.TYPES.ATTACHMENT.TIME
  ]
  Model: ReviewlessCampgroundAttachment
  ParentModel: ReviewlessCampground

module.exports = new ReviewlessCampgroundAttachmentCtrl()
