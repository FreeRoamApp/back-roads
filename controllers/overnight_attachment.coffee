Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
OvernightAttachment = require '../models/overnight_attachment'
Overnight = require '../models/overnight'
AttachmentBaseCtrl = require './attachment_base'

class OvernightAttachmentCtrl extends AttachmentBaseCtrl
  type: 'overnightAttachment'
  defaultEmbed: [
    EmbedService.TYPES.ATTACHMENT.USER, EmbedService.TYPES.ATTACHMENT.TIME
  ]
  Model: OvernightAttachment
  ParentModel: Overnight

module.exports = new OvernightAttachmentCtrl()
