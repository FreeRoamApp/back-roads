Promise = require 'bluebird'
_ = require 'lodash'

Campground = require '../models/campground'
PlaceBaseCtrl = require './place_base'
EmbedService = require '../services/embed'
config = require '../config'

class CampgroundCtrl extends PlaceBaseCtrl
  type: 'campground'
  Model: Campground
  defaultEmbed: [EmbedService.TYPES.CAMPGROUND.ATTACHMENTS_PREVIEW]

  upsert: ({id}) =>
    console.log 'upsert', arguments[0]
    super

module.exports = new CampgroundCtrl()
