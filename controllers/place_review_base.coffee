Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EarnAction = require '../models/earn_action'
UserRig = require '../models/user_rig'
Vote = require '../models/vote'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
cknex = require '../services/cknex'
config = require '../config'

embedMyVotes = (reviews, reviewVotes) ->
  _.map reviews, (review) ->
    review.myVote = _.find reviewVotes, ({parentId}) ->
      "#{parentId}" is "#{review.id}"
    # review.children = embedMyVotes review.children, reviewVotes
    review

module.exports = class PlaceReviewBaseCtrl
  imageFolder: 'rv'

  userEmbed: [EmbedService.TYPES.REVIEW.PARENT]

  getParentDiff: ({parent, extras, operator}) ->
    operator ?= 'add'
    multiplier = if operator is 'add' then 1 else -1
    _.reduce extras, (diff, addValue, key) ->
      valueKey = if key is 'cellSignal' then 'signal' else 'value'
      if typeof addValue is 'object' # seasonal, cell, day/night
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

  getAllByParentId: ({parentId}, {user}) =>
    @Model.getAllByParentId parentId
    .map EmbedService.embed {embed: @defaultEmbed}
    .then (reviews) =>
      Vote.getAllByUserIdAndTopIdAndParentType user.id, parentId, @type
      .then (votes) ->
        embedMyVotes reviews, votes

  getById: ({id}, {user}) =>
    @Model.getById id
    .then EmbedService.embed {embed: [EmbedService.TYPES.REVIEW.EXTRAS]}

  search: ({query}, {user}) =>
    @Model.search {query}
    .then (reviews) =>
      _.map reviews, (review) =>
        _.defaults {@type}, review
    .then (results) =>
      Promise.map results, EmbedService.embed {embed: @defaultEmbed}

  getAllByUserId: ({userId}) =>
    @Model.getAllByUserId userId
    .map EmbedService.embed {embed: @userEmbed}

  upsertAttachments: (attachments, {parentId, userId}) =>
    @AttachmentModel.batchUpsert _.map attachments, (attachment) =>
      attachment.parentType = @parentType
      attachment = _.pick attachment, [
        'id', 'caption', 'tags', 'type', 'aspectRatio', 'location'
        'prefix', 'parentType'
      ]
      _.defaults attachment, {parentId, userId}

  upsert: (options, {user, headers, connection}) =>
    {id, type, title, body, rating, attachments, extras, parentId} = options

    # assign every attachment an id
    attachments = _.map attachments, (attachment) ->
      _.defaults attachment, {id: cknex.getTimeUuid()}

    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    body = body.trim()

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post...'

    if not body and user.username isnt 'austin'
      router.throw status: 400, info: 'can\'t be empty'

    isUpdate = Boolean id

    Promise.all [
      if isUpdate
        @Model.getById id
        .then EmbedService.embed {embed: [EmbedService.TYPES.REVIEW.EXTRAS]}
      else
        Promise.resolve null

      @ParentModel.getById parentId

      UserRig.getByUserId user.id

      if isUpdate
        Promise.resolve null
      else
        EarnAction.completeActionByUserId(
          user.id
          'review'
        ).catch -> null
    ]
    .then ([existingReview, parent, userRig]) =>
      if existingReview and (
        "#{existingReview.userId}" isnt "#{user.id}" and
          user.username isnt 'austin'
      )
        router.throw status: 401, info: 'unauthorized'

      totalStars = parent.rating * parent.ratingCount
      if isUpdate
        totalStars -= existingReview.rating
        totalStars += rating
        newRatingCount = parent.ratingCount
      else
        totalStars += rating
        newRatingCount = parent.ratingCount + 1
      newRating = totalStars / newRatingCount

      newAttachmentCount = (parent.attachmentCount or 0) +
                            (attachments?.length or 0)

      parentUpsert = {
        id: parent.id, slug: parent.slug
        rating: newRating, ratingCount: newRatingCount
        attachmentCount: newAttachmentCount
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

      # TODO: choose a good thumbnail for each campground instead of most recent
      if attachments?[0]
        parentUpsert.thumbnailPrefix = attachments[0].prefix

      (if user?.username is 'austin' and not rating
        Promise.all _.filter [
          if parentUpsert.thumbnailPrefix
            @ParentModel.upsert _.omit parentUpsert, ['rating', 'ratingCount']

          Promise.resolve {id: null}
        ]
      else
        Promise.all [
          @ParentModel.upsert parentUpsert
          @Model.upsert
            id: id
            userId: existingReview?.userId or user.id
            title: title
            body: body
            parentId: parentId
            parentType: @parentType
            rating: rating
            attachments: attachments
            rigType: userRig?.type
            rigLength: userRig?.length
        ]
      ).tap ([parentUpsert, review]) =>
        Promise.all _.filter [
          unless id # TODO handle photo updates on review edits?
            @upsertAttachments attachments, {parentId, userId: user.id}

          if extras
            console.log 'up extras', extras
            @upsertExtras {
              id: review?.id, parent, extras, existingReview
            }, {user}
        ]

  uploadImage: ({}, {user, file}) =>
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: @imageFolder}
    )

  deleteAttachments: (attachments) =>
    Promise.map attachments, @AttachmentModel.deleteByRow

  deleteById: ({id}, {user}) =>
    Promise.all _.filter [
      @Model.getById id
      @Model.getExtrasById? id
    ]
    .then ([review, extras]) =>
      hasPermission = "#{review.userId}" is "#{user.id}" or
                        user.username is 'austin'
      unless hasPermission
        router.throw
          status: 400, info: 'You don\'t have permission to do that'

      @ParentModel.getById review.parentId
      .then (parent) =>
        totalStars = parent.rating * parent.ratingCount
        totalStars -= review.rating
        newRatingCount = parent.ratingCount - 1
        newRating = totalStars / newRatingCount

        parentUpsert = {
          id: parent.id, slug: parent.slug
          rating: newRating, ratingCount: newRatingCount
        }

        Promise.all _.filter [
          @ParentModel.upsert parentUpsert

          @Model.deleteByRow review

          @deleteAttachments _.map review.attachments, (attachment) ->
            _.defaults attachment, {
              parentId: review.parentId, userId: review.userId
            }
          .catch (err) ->
            console.log 'delete attachments err'

          if extras
            Promise.delay 100 # HACK: below upserts parentModel, which can't be done simultaneously with above
            .then =>
              @deleteExtras {parent, extras, id: review.id}
        ]
