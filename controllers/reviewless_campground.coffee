Promise = require 'bluebird'
_ = require 'lodash'

ReviewlessCampground = require '../models/reviewless_campground'
PlaceBaseCtrl = require './place_base'
EmbedService = require '../services/embed'
config = require '../config'

class ReviewlessCampgroundCtrl extends PlaceBaseCtrl
  type: 'reviewlessCampground'
  Model: ReviewlessCampground
  defaultEmbed: [EmbedService.TYPES.REVIEWLESS_CAMPGROUND.ATTACHMENTS_PREVIEW]

module.exports = new ReviewlessCampgroundCtrl()
