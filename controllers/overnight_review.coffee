Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
PlaceReviewService = require '../services/place_review'
OvernightAttachment = require '../models/overnight_attachment'
OvernightReview = require '../models/overnight_review'
Overnight = require '../models/overnight'
PlaceReviewBaseCtrl = require './place_review_base'

VALID_EXTRAS = [
  'noise', 'safety', 'cellSignal'
]

class OvernightReviewCtrl extends PlaceReviewBaseCtrl
  type: 'overnightReview'
  parentType: 'overnight'
  imageFolder: 'rvov'
  defaultEmbed: [EmbedService.TYPES.REVIEW.USER, EmbedService.TYPES.REVIEW.TIME]
  Model: OvernightReview
  ParentModel: Overnight
  AttachmentModel: OvernightAttachment

  upsertExtras: ({id, parent, extras, existingReview}, {user}) =>
    # remove old values so we can replace with new
    # doing so updates the averages properly, easily...
    # alternative is calculating what the difference should be (which is
    # the better approach, just harder to code)
    (if existingReview?.extras
      @deleteExtras {id, parent, extras: existingReview.extras}
      .then =>
        @ParentModel.getById parent.id
    else
      Promise.resolve parent
    ).then (parent) =>
      extras = _.pickBy extras, (extra, key) ->
        key in VALID_EXTRAS and (
          typeof extra is 'number' or not _.isEmpty extra
        )

      # TODO allow specifying day/night noise
      if extras.noise
        extras.noise = {day: extras.noise, night: extras.noise}

      # update averages
      parentDiff = PlaceReviewService.getParentDiffFromExtras {
        parent, extras, operator: 'add'
      }

      @ParentModel.upsertByRow parent, parentDiff

      if id # id isnt there if just updating the parent w/o review
        OvernightReview.upsertExtras _.defaults {id, userId: user.id}, extras

  deleteExtras: ({id, parent, extras}) =>
    extras = _.pickBy extras, (extra, key) ->
      key in VALID_EXTRAS and (typeof extra is 'number' or not _.isEmpty extra)

    # update averages
    parentDiff = PlaceReviewService.getParentDiffFromExtras {
      parent, extras, operator: 'sub'
    }
    Promise.all [
      @ParentModel.upsertByRow parent, parentDiff

      OvernightReview.deleteExtrasById id
    ]

module.exports = new OvernightReviewCtrl()
