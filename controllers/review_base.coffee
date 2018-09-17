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
    .then (results) ->
      Promise.map results, EmbedService.embed {embed: @defaultEmbed}

  upsert: (options, {user, headers, connection}) =>
    {id, type, title, body, rating, attachments, parentId} = options

    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    body = body.trim()

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post...'

    unless body
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

      Promise.all [
        @ParentModel.upsert {
          id: parent.id, slug: parent.slug
          rating: newRating, ratingCount: newRatingCount
        }
        @Model.upsert
          id: id
          userId: user.id
          title: title
          body: body
          parentId: parentId
          rating: rating
          attachments: attachments
      ]

  uploadImage: ({}, {user, file}) =>
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: @imageFolder}
    )
