Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EarnAction = require '../models/earn_action'
CheckIn = require '../models/check_in'
Trip = require '../models/trip'
UserRig = require '../models/user_rig'
Vote = require '../models/vote'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
CheckInService = require '../services/check_in'
EmailService = require '../services/email'
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
        @ParentModel.upsertByRow parent, parentUpsert
        @Model.upsert
          id: id
          userId: user.id
          parentId: parentId
          parentType: @parentType
          rating: rating
          rigType: userRig?.type
          rigLength: userRig?.length
      ]

  upsert: (options, {user}) =>
    console.log 'upsert rev', options
    if not options?.body and user.username isnt 'austin'
      router.throw {
        status: 400
        info:
          langKey: 'error.emptyReview'
          step: 'review'
          field: 'body'
      }

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post...'

    EmailService.queueSend {
      to: EmailService.EMAILS.EVERYONE
      subject: "New review by #{user.username}"
      text: """
      https://freeroam.app/user/#{user.username}

      #{JSON.stringify options, null, '\t'}
      """
    }

    PlaceReviewService.upsertByParentType(
      @parentType, options, {userId: user.id}
    )

  uploadImage: ({}, {user, file}) =>
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: @imageFolder}
    )

  deleteById: ({id}, {user}) =>
    PlaceReviewService.deleteByParentTypeAndId @parentType, id, {user}
