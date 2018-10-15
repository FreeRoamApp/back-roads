Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EmbedService = require '../services/embed'
ImageService = require '../services/image'
config = require '../config'

module.exports = class ReviewBaseCtrl
  imageFolder: 'rv'
  getAllByParentId: ({parentId}, {user}) =>
    @Model.getAllByParentId parentId
    .map EmbedService.embed {embed: @defaultEmbed}

  search: ({query}, {user}) =>
    @Model.search {query}
    .then (reviews) =>
      _.map reviews, (review) =>
        _.defaults {@type}, review
    .then (results) =>
      Promise.map results, EmbedService.embed {embed: @defaultEmbed}

  upsertAttachments: (attachments, {parentId, userId}) =>
    @AttachmentModel.batchUpsert _.map attachments, (attachment) ->
      attachment = _.pick attachment, [
        'caption', 'tags', 'type', 'aspectRatio', 'location'
        'src', 'largeSrc', 'smallSrc'
      ]
      _.defaults attachment, {parentId, userId}

  upsert: (options, {user, headers, connection}) =>
    {id, type, title, body, rating, attachments, extras, parentId} = options

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
      (if isUpdate then @Model.getById id else Promise.resolve null)
      @ParentModel.getById parentId
    ]
    .then ([existingReview, parent]) =>
      totalStars = parent.rating * parent.ratingCount
      totalStars += rating
      newRatingCount = parent.ratingCount + 1
      newRating = totalStars / newRatingCount

      parentUpsert = {
        id: parent.id, slug: parent.slug
        rating: newRating, ratingCount: newRatingCount
      }
      # TODO: choose a good thumbnail for each campground instead of most recent
      if attachments?[0]?.smallSrc
        parentUpsert.thumbnailUrl = attachments?[0]?.smallSrc

      (if user?.username is 'austin' and not rating
        Promise.resolve [null, {id: null}]
      else
        Promise.all [
          @ParentModel.upsert parentUpsert
          @Model.upsert
            id: id
            userId: user.id
            title: title
            body: body
            parentId: parentId
            rating: rating
            attachments: attachments
        ]
      ).tap ([parentUpsert, review]) =>
        Promise.all _.filter [
          unless id # TODO handle photo updates on review edits?
            @upsertAttachments attachments, {parentId, userId: user.id}

          if extras
            @upsertExtras {id: review.id, parent, extras}, {user}
        ]

  uploadImage: ({}, {user, file}) =>
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: @imageFolder}
    )

  deleteById: ({id}, {user}) =>
    @Model.getById id
    .then (review) =>
      hasPermission = review.userId is user.id or user.username is 'austin'
      unless hasPermission
        router.throw
          status: 400, info: 'You don\'t have permission to do that'
      @Model.deleteByRow review
