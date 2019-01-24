Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

Overnight = require '../models/overnight'
EmbedService = require '../services/embed'
PlaceBaseCtrl = require './place_base'

class OvernightCtrl extends PlaceBaseCtrl
  type: 'overnight'
  Model: Overnight
  defaultEmbed: [EmbedService.TYPES.OVERNIGHT.ATTACHMENTS_PREVIEW]

  getIsAllowedByMeAndId: ({id}, {user}) ->
    Overnight.getIsOvernightAllowedByUserIdAndOvernightId user.id, id

  markIsAllowedById: ({id, isAllowed}, {user}) ->
    Promise.all [
      Overnight.getById id
      Overnight.getIsOvernightAllowedByUserIdAndOvernightId user.id, id
    ]
    .then ([overnight, isAllowedByMe]) ->
      if isAllowedByMe
        router.throw status: 400, info: 'already voted'
      isAllowedCount = overnight.isAllowedCount or 0
      isNotAllowedCount = overnight.isNotAllowedCount or 0
      if isAllowed
        isAllowedCount += 1
      else
        isNotAllowedCount += 1

      isAllowedScore = Math.round(
        100 * isAllowedCount / (isAllowedCount + isNotAllowedCount)
      ) / 100

      Promise.all [
        Overnight.upsertIsAllowed {
          userId: user.id
          overnightId: id
          isAllowed: isAllowed
        }
        Overnight.upsertByRow overnight, {
          isAllowedCount
          isNotAllowedCount
          isAllowedScore
        }
      ]

module.exports = new OvernightCtrl()
