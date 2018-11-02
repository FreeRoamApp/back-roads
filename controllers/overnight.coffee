Promise = require 'bluebird'
_ = require 'lodash'

Overnight = require '../models/overnight'
EmbedService = require '../services/embed'
PlaceBaseCtrl = require './place_base'

class OvernightCtrl extends PlaceBaseCtrl
  type: 'overnight'
  Model: Overnight
  defaultEmbed: [EmbedService.TYPES.OVERNIGHT.ATTACHMENTS_PREVIEW]

module.exports = new OvernightCtrl()
