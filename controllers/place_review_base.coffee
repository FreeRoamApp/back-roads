Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EarnAction = require '../models/earn_action'
UserRig = require '../models/user_rig'
Vote = require '../models/vote'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
PlaceReviewService = require '../services/place_review'
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

  getByUserIdAndParentId: ({userId, parentId}) =>
    # ideally place_reviews_by_userId would have primaryKey
    # (userId, [parentId, id]), but it doesn't....
    @Model.getAllByUserId userId
    .then (placeReviews) ->
      _.find placeReviews, (placeReview) ->
        "#{placeReview.parentId}" is "#{parentId}"
    .then EmbedService.embed {embed: @userEmbed}

  getCountByUserId: ({userId}) =>
    @Model.getCountByUserId userId

  upsertAttachments: (attachments, {parentId, userId}) =>
    @AttachmentModel.batchUpsert _.map attachments, (attachment) =>
      attachment.parentType = @parentType
      attachment = _.pick attachment, [
        'id', 'caption', 'tags', 'type', 'aspectRatio', 'location'
        'prefix', 'parentType'
      ]
      _.defaults attachment, {parentId, userId}

  upsertRatingOnly: ({id, parentId, rating}, {user}) =>
    isUpdate = Boolean id
    Promise.all [
      if isUpdate
        @Model.getById id
        .then EmbedService.embed {embed: [EmbedService.TYPES.REVIEW.EXTRAS]}
      else
        Promise.resolve null
      @ParentModel.getById parentId
      UserRig.getByUserId user.id
    ]
    .then ([existingReview, parent, userRig]) =>
      parentUpsert = PlaceReviewService.getParentDiff parent, rating, {
        existingReview, userRig
      }
      Promise.all [
        @ParentModel.upsert parentUpsert
        @Model.upsert
          id: id
          userId: user.id
          parentId: parentId
          parentType: @parentType
          rating: rating
          rigType: userRig?.type
          rigLength: userRig?.length
      ]

  upsert: (options, {user, headers, connection}) =>
    {id, type, title, body, rating, attachments, extras, parentId} = options

    console.log 'upsert review', options

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
      router.throw {
        status: 400
        info:
          langKey: 'error.emptyReview'
          step: 'review'
          field: 'body'
      }

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

      parentUpsert = PlaceReviewService.getParentDiff parent, rating, {
        existingReview, userRig
      }
      newAttachmentCount = (parent.attachmentCount or 0) +
                            (attachments?.length or 0)

      parentUpsert.attachmentCount = newAttachmentCount


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
