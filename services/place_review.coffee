_ = require 'lodash'
Promise = require 'bluebird'

CampgroundReview = require '../models/campground_review'
OvernightReview = require '../models/overnight_review'
AmenityReview = require '../models/amenity_review'
CampgroundAttachment = require '../models/campground_attachment'
OvernightAttachment = require '../models/overnight_attachment'
AmenityAttachment = require '../models/amenity_attachment'
Campground = require '../models/campground'
Overnight = require '../models/overnight'
Amenity = require '../models/amenity'
EarnAction = require '../models/earn_action'
UserRig = require '../models/user_rig'
cknex = require './cknex'
EmbedService = require './embed'

PLACE_REVIEW_TYPES =
  campgroundReview: CampgroundReview
  overnightReview: OvernightReview
  amenityReview: AmenityReview

PLACE_TYPES =
  campground: Campground
  overnight: Overnight
  amenity: Amenity

PLACE_ATTACHMENT_TYPES =
  campground: CampgroundAttachment
  overnight: OvernightAttachment
  amenity: AmenityAttachment

SEASONS = ['winter', 'spring', 'summer', 'fall']
VALID_CAMPGROUND_EXTRAS = [
  'roadDifficulty', 'cleanliness', 'crowds', 'fullness', 'noise',
  'shade', 'safety', 'cellSignal', 'pricePaid'
]
VALID_OVERNIGHT_EXTRAS = [
  'noise', 'safety', 'cellSignal'
]

class PlaceReviewService
  upsertByParentType: (parentType, row, {userId, preserveCounts}) =>
    {id, type, title, body, rating, attachments, extras, parentId} = row

    Model = PLACE_REVIEW_TYPES["#{parentType}Review"]
    ParentModel = PLACE_TYPES[parentType]

    # assign every attachment an id
    attachments = _.map attachments, (attachment) ->
      _.defaults attachment, {id: cknex.getTimeUuid()}

    body = body.trim()

    isUpdate = Boolean id

    Promise.all [
      if isUpdate
        Model.getById id
        .then EmbedService.embed {embed: [EmbedService.TYPES.REVIEW.EXTRAS]}
      else
        Promise.resolve null

      ParentModel.getById parentId

      UserRig.getByUserId userId

      if isUpdate
        Promise.resolve null
      else
        EarnAction.completeActionByUserId(
          userId
          'review'
        ).catch -> null
    ]
    .then ([existingReview, parent, userRig]) =>
      console.log existingReview?.parentId, parentId
      # when migrating reviews, there will be an existing that doesn't match
      if existingReview?.parentId isnt parentId
        existingReview = null

      if existingReview and (
        "#{existingReview.userId}" isnt "#{userId}" and
          user.username isnt 'austin'
      )
        router.throw status: 401, info: 'unauthorized'

      console.log 'existingReview', Boolean existingReview

      parentUpsert = @getParentDiff parent, rating, {
        existingReview, userRig
      }
      newAttachmentCount = (parent.attachmentCount or 0) +
                            (attachments?.length or 0)

      parentUpsert.attachmentCount = newAttachmentCount


      # TODO: choose a good thumbnail for each campground instead of most recent
      if attachment = _.find(attachments, {type: 'image'})
        parentUpsert.thumbnailPrefix = attachment.prefix

      videoAttachment = _.find(attachments, {type: 'video'})
      if videoAttachment
        if _.isEmpty(parent.videos) # legacy fix for videos: {}
          parent.videos = []
        parentUpsert.videos = parent.videos.concat {
          sourceType: 'youtube', sourceId: videoAttachment.prefix
        }

      console.log 'gogogo'
      console.log '---'
      console.log 'parent up', parentUpsert

      (if user?.username is 'austin' and not rating
        Promise.all _.filter [
          if parentUpsert.thumbnailPrefix and not preserveCounts
            ParentModel.upsertByRow parent, _.omit parentUpsert, ['rating', 'ratingCount']

          Promise.resolve {id: null}
        ]
      else
        Promise.all [
          unless preserveCounts
            ParentModel.upsertByRow parent, parentUpsert
          Model.upsert
            id: id
            userId: existingReview?.userId or userId
            title: title
            body: body
            parentId: parentId
            parentType: parentType
            rating: rating
            attachments: attachments
            rigType: userRig?.type
            rigLength: userRig?.length
        ]
      ).tap ([parentUpsert, review]) =>
        Promise.all _.filter [
          unless id # TODO handle photo updates on review edits?
            @upsertAttachmentsByParentType(
              parentType, attachments, {parentId, userId: userId}
            )

          if extras
            console.log 'up extras', extras
            @["#{parentType}UpsertExtras"] {
              id: review?.id, parent, extras, existingReview
            }, {userId, preserveCounts}
        ]

  deleteByParentTypeAndId: (parentType, id, {user, hasPermission, preserveCounts} = {}) =>
    Model = PLACE_REVIEW_TYPES["#{parentType}Review"]
    ParentModel = PLACE_TYPES[parentType]

    Promise.all _.filter [
      Model.getById id
      Model.getExtrasById? id
    ]
    .then ([review, extras]) =>
      hasPermission ?= "#{review.userId}" is "#{user.id}" or
                        user.username is 'austin'
      unless hasPermission
        router.throw
          status: 400, info: 'You don\'t have permission to do that'


      ParentModel.getById review.parentId
      .then (parent) =>
        totalStars = parent.rating * parent.ratingCount
        totalStars -= review.rating
        newRatingCount = parent.ratingCount - 1
        newRating = totalStars / newRatingCount

        parentUpsert = {
          rating: newRating, ratingCount: newRatingCount
        }

        Promise.all _.filter [
          unless preserveCounts
            ParentModel.upsertByRow parent, parentUpsert

          Model.deleteByRow review

          @deleteAttachmentsByParentType(
            parentType
            _.map review.attachments, (attachment) ->
              _.defaults attachment, {
                parentId: review.parentId, userId: review.userId
              }
          )
          .catch (err) ->
            console.log 'delete attachments err'

          if extras
            Promise.delay 100 # HACK: below upserts parentModel, which can't be done simultaneously with above
            .then =>
              @["#{parentType}DeleteExtras"] {parent, extras, id: review.id}
        ]

  deleteAttachmentsByParentType: (parentType, attachments) =>
    AttachmentModel = PLACE_ATTACHMENT_TYPES[parentType]
    Promise.map attachments, AttachmentModel.deleteByRow

  upsertAttachmentsByParentType: (parentType, attachments, {parentId, userId}) =>
    AttachmentModel = PLACE_ATTACHMENT_TYPES[parentType]
    AttachmentModel.batchUpsert _.map attachments, (attachment) =>
      attachment.parentType = @parentType
      attachment = _.pick attachment, [
        'id', 'caption', 'tags', 'type', 'aspectRatio', 'location'
        'prefix', 'parentType'
      ]
      _.defaults attachment, {parentId, userId}

  getParentDiffFromExtras: ({parent, extras, operator}) ->
    operator ?= 'add'
    multiplier = if operator is 'add' then 1 else -1
    _.reduce extras, (diff, addValue, key) ->
      if key in ['userId', 'id']
        return diff
      valueKey = if key is 'cellSignal' then 'signal' else 'value'
      if addValue and typeof addValue is 'object' # seasonal, cell, day/night
        diff[key] = parent[key] or {}
        _.forEach addValue, (subAddValue, subKey) ->
          value = parent[key]?[subKey]?[valueKey] or 0
          count = parent[key]?[subKey]?.count or 0
          newCount = count + (1 * multiplier)
          if newCount is 0
            newValue = 0
          else
            newValue = (value * count + (subAddValue * multiplier)) / newCount
            newValue = Math.round(newValue * 10000) / 10000 # x.xxxx
          diff[key] = _.defaults {
            "#{subKey}":
              "#{valueKey}": newValue
              count: newCount
          }, diff[key]
      else if addValue
        value = parent[key]?[valueKey] or 0
        count = parent[key]?.count or 0
        newCount = count + (1 * multiplier)
        if newCount is 0
          newValue = 0
        else
          newValue = (value * count + (addValue * multiplier)) / newCount
          newValue = Math.round(newValue * 10000) / 10000 # x.xxxx
        diff[key] = _.defaults {
          "#{valueKey}": newValue
          count: newCount
        }
      diff
    , {}

  getParentDiff: (parent, rating, {existingReview, userRig} = {}) ->
    totalStars = (parent.rating or 0) * (parent.ratingCount or 0)
    if existingReview
      totalStars or= existingReview.rating
      totalStars -= existingReview.rating
      totalStars += rating
      newRatingCount = parent.ratingCount
    else
      totalStars += rating
      newRatingCount = parent.ratingCount + 1
    newRating = totalStars / newRatingCount

    parentUpsert = {
      rating: newRating, ratingCount: newRatingCount
    }

    # update maxLength and allowedTypes if we can
    if rating > 3 and userRig
      # TODO: problem with this is it's more of a maxReportedLength
      maxLength = parent.maxLength or 0
      if userRig.length > maxLength and userRig.length < 60
        parentUpsert.maxLength = userRig.length

      allowedTypes = parent.allowedTypes or {}
      if userRig.type and not allowedTypes[userRig.type]
        parentUpsert.allowedTypes = _.defaults {
          "#{userRig.type}": true
        }, allowedTypes

    parentUpsert











  campgroundUpsertExtras: ({id, parent, extras, existingReview}, {userId, preserveCounts}) =>
    # remove old values so we can replace with new
    # doing so updates the averages properly, easily...
    # alternative is calculating what the difference should be (which is
    # the better approach, just harder to code)
    (if existingReview?.extras
      @campgroundDeleteExtras {id, parent, extras: existingReview.extras}
      .then =>
        Campground.getById parent.id
    else
      Promise.resolve parent
    ).then (parent) =>
      extras = _.pickBy extras, (extra, key) ->
        key in VALID_CAMPGROUND_EXTRAS and (
          typeof extra is 'number' or not _.isEmpty extra
        )

      # TODO allow specifying day/night noise
      if extras.noise
        extras.noise = {day: extras.noise, night: extras.noise}

      # update averages
      parentDiff = @getParentDiffFromExtras {
        parent, extras, operator: 'add'
      }

      # HACK: TODO: change to calculate from all price data points
      if extras.pricePaid?
        extras.pricePaid = parseInt extras.pricePaid
        delete parentDiff.pricePaid
        parentDiff.prices = {
          all: {
            min: parseInt extras.pricePaid
            max: parseInt extras.pricePaid
            mode: parseInt extras.pricePaid
            avg: parseInt extras.pricePaid
          }
        }

      # if this campground doesn't have a value for a certain season, set it to
      # whatever value we have, as an estimate
      _.forEach Campground.seasonalFields, (field) ->
        _.forEach SEASONS, (season) ->
          if parentDiff[field] and not parent[season]?.count and
              not parentDiff[field][season]
            value = _.first(_.values(parentDiff[field]))?.value
            if value
              parentDiff[field][season] = {value, count: 0}

      Promise.all [
        unless preserveCounts
          Campground.upsertByRow parent, parentDiff

        if id # id isnt there if just updating the parent w/o review
          CampgroundReview.upsertExtras _.defaults {id, userId: userId}, extras
      ]

  campgroundDeleteExtras: ({id, parent, extras}) =>
    extras = _.pickBy extras, (extra, key) ->
      key in VALID_CAMPGROUND_EXTRAS and (typeof extra is 'number' or not _.isEmpty extra)

    # update averages
    parentDiff = @getParentDiffFromExtras {
      parent, extras, operator: 'sub'
    }
    Promise.all [
      Campground.upsertByRow parent, parentDiff

      CampgroundReview.deleteExtrasById id
    ]










  overnightUpsertExtras: ({id, parent, extras, existingReview}, {userId, preserveCounts}) =>
    # remove old values so we can replace with new
    # doing so updates the averages properly, easily...
    # alternative is calculating what the difference should be (which is
    # the better approach, just harder to code)
    (if existingReview?.extras
      @overnightDeleteExtras {id, parent, extras: existingReview.extras}
      .then =>
        Overnight.getById parent.id
    else
      Promise.resolve parent
    ).then (parent) =>
      extras = _.pickBy extras, (extra, key) ->
        key in VALID_OVERNIGHT_EXTRAS and (
          typeof extra is 'number' or not _.isEmpty extra
        )

      # TODO allow specifying day/night noise
      if extras.noise
        extras.noise = {day: extras.noise, night: extras.noise}

      # update averages
      parentDiff = @getParentDiffFromExtras {
        parent, extras, operator: 'add'
      }

      Promise.all [
        unless preserveCounts
          Overnight.upsertByRow parent, parentDiff

        if id # id isnt there if just updating the parent w/o review
          OvernightReview.upsertExtras _.defaults {id, userId: userId}, extras
      ]

  overnightDeleteExtras: ({id, parent, extras}) =>
    extras = _.pickBy extras, (extra, key) ->
      key in VALID_OVERNIGHT_EXTRAS and (typeof extra is 'number' or not _.isEmpty extra)

    # update averages
    parentDiff = @getParentDiffFromExtras {
      parent, extras, operator: 'sub'
    }
    Promise.all [
      Overnight.upsertByRow parent, parentDiff

      OvernightReview.deleteExtrasById id
    ]






  amenityUpsertExtras: ({id, parent, extras, existingReview}, {userId}) ->
    Promise.resolve null

  amenityDeleteExtras: ({id, parent, extras}) ->
    Promise.resolve null

module.exports = new PlaceReviewService()
