Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
ImageService = require '../services/image'
config = require '../config'

module.exports = class ReviewBaseCtrl
  imageFolder: 'rv'
  getAllByParentId: ({parentId}, {user}) =>
    @Model.getAllByParentId parentId
    # .then EmbedService.embed {embed: defaultEmbed}

  search: ({query}, {user}) =>
    @Model.search {query}
    .then (places) =>
      _.map places, (place) =>
        _.defaults {@type}, place
    # .then (results) ->
    #   Promise.map results, EmbedService.embed {embed: defaultEmbed}

  upsert: (options, {user, headers, connection}) =>
    {id, type, title, body, attachments, parentId} = options

    userAgent = headers['user-agent']
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress

    body = body.trim()

    if user.flags.isChatBanned
      router.throw status: 400, info: 'unable to post...'

    unless body
      router.throw status: 400, info: 'can\'t be empty'

    @Model.upsert
      userId: user.id
      body: body
      parentId: parentId

  uploadImage: ({}, {user, file}) =>
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: @imageFolder}
    )
