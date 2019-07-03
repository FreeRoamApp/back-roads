Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

Event = require '../models/event'
EventReview = require '../models/overnight_review' # FIXME FIXME
EmbedService = require '../services/embed'
PlaceBaseCtrl = require './place_base'

class EventCtrl extends PlaceBaseCtrl
  type: 'event'
  Model: Event
  ReviewModel: EventReview
  defaultEmbed: [EmbedService.TYPES.EVENT.ATTACHMENTS_PREVIEW]

  getAll: ->
    Event.getAll()

module.exports = new EventCtrl()
