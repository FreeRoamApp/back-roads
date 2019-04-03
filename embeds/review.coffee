_ = require 'lodash'

BaseMessage = require './base_message'
# FIXME: work with other types. probably should extend from base_review embed
CampgroundReview = require '../models/campground_review'
PlacesService = require '../services/places'
cknex = require '../services/cknex'

class ReviewEmbed
  user: (review) ->
    if review.userId
      BaseMessage.user {
        userId: review.userId
      }

  extras: (review) ->
    CampgroundReview.getExtrasById review.id

  time: (review) ->
    id = if typeof review.id is 'string' \
               then cknex.getTimeUuidFromString review.id
               else review.id
    id.getDate()

  parent: (review) ->
    PlacesService.getByTypeAndId review.parentType, review.parentId


module.exports = new ReviewEmbed()
