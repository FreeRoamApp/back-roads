Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
CampgroundAttachment = require '../models/campground_attachment'
Campground = require '../models/campground'
AttachmentBaseCtrl = require './attachment_base'

class CampgroundAttachmentCtrl extends AttachmentBaseCtrl
  type: 'campgroundAttachment'
  defaultEmbed: [EmbedService.TYPES.ATTACHMENT.USER, EmbedService.TYPES.ATTACHMENT.TIME]
  Model: CampgroundAttachment
  ParentModel: Campground

module.exports = new CampgroundAttachmentCtrl()
