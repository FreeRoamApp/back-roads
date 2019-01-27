_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

module.exports = class AttachmentBase extends Base
  getScyllaTables: ->
    [
      # TODO: do we need this table?
      {
        name: 'attachments_counter_by_id'
        ignoreUpsert: true
        fields:
          id: 'timeuuid'
          upvotes: 'counter'
          downvotes: 'counter'
        primaryKey:
          partitionKey: ['id']
          clusteringColumns: null
      }
    ]

  getById: (id) =>
    cknex().select '*'
    .from @getScyllaTables()[1].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getAllByParentId: (parentId) =>
    Promise.all [
      cknex().select '*'
      .from @getScyllaTables()[0].name
      .where 'parentId', '=', parentId
      .run()
      .map @defaultOutput

      cknex().select '*'
      .from @getScyllaTables()[4].name
      .where 'parentId', '=', parentId
      .run()
    ]
    .then ([allAttachments, voteCounts]) ->
      allAttachments = _.map allAttachments, (attachment) ->
        voteCount = _.find voteCounts, {id: attachment.id}
        voteCount ?= {upvotes: 0, downvotes: 0}
        attachment.upvotes = voteCount.upvotes
        attachment.downvotes = voteCount.downvotes
        attachment

  getAllByUserId: (userId) ->
    Promise.all [
      cknex().select '*'
      .from @getScyllaTables()[2].name
      .where 'userId', '=', userId
      .run()
      .map @defaultOutput

      cknex().select '*'
      .from @getScyllaTables()[3].name
      .where 'userId', '=', userId
      .run()
    ]
    .then ([allAttachments, voteCounts]) ->
      allAttachments = _.map allAttachments, (attachment) ->
        voteCount = _.find voteCounts, {id: attachment.id}
        voteCount ?= {upvotes: 0, downvotes: 0}
        attachment.upvotes = voteCount.upvotes
        attachment.downvotes = voteCount.downvotes
        attachment

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .limit limit
    .run()
    .map @defaultOutput
