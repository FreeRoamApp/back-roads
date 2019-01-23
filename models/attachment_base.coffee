_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

module.exports = class AttachmentBase extends Base
  getScyllaTables: ->
    [
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
    cknex().select '*'
    .from @getScyllaTables()[0].name
    .where 'parentId', '=', parentId
    .run()
    .map @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @getScyllaTables()[0].name
    .limit limit
    .run()
    .map @defaultOutput
