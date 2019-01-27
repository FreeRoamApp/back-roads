Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EmbedService = require '../services/embed'
config = require '../config'

module.exports = class AttachmentBaseCtrl
  getAllByParentId: ({parentId}, {user}) =>
    @Model.getAllByParentId parentId
    .map EmbedService.embed {embed: @defaultEmbed}

  getAllByUserId: ({userId}, {user}) =>
    @Model.getAllByUserId userId
    # .map EmbedService.embed {embed: @defaultEmbed}

  deleteByRow: ({row}, {user}) =>
    @Model.getById row.id
    .then (attachment) =>
      unless user.username is 'austin' or "#{attachment.userId}" is "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}
      @Model.deleteByRow row
