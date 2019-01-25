Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
AmenityAttachment = require '../models/amenity_attachment'
Amenity = require '../models/amenity'
AttachmentBaseCtrl = require './attachment_base'

class AmenityAttachmentCtrl extends AttachmentBaseCtrl
  type: 'amenityAttachment'
  defaultEmbed: [
    EmbedService.TYPES.ATTACHMENT.USER, EmbedService.TYPES.ATTACHMENT.TIME
  ]
  Model: AmenityAttachment
  ParentModel: Amenity

module.exports = new AmenityAttachmentCtrl()
