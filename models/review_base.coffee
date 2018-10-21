_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

module.exports = class ReviewBase extends Base
  search: ({query}) =>
    elasticsearch.search {
      index: @ELASTICSEARCH_INDICES[0].name
      type: @ELASTICSEARCH_INDICES[0].name
      body:
        query: query
        from : 0
        size : 250
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        {slug: _id, title: _source.title, details: _source.details}

  getById: (id) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[2].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput

  getAllByParentId: (parentId) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'parentId', '=', parentId
    .run()
    .map @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .limit limit
    .run()
    .map @defaultOutput

  getExtrasById: (id) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[3].name
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultExtrasOutput

  upsertExtras: (extras) =>
    extras = @defaultExtrasInput extras

    cknex().update @SCYLLA_TABLES[3].name
    .set _.omit extras, ['id']
    .where 'id', '=', extras.id
    .run()

  deleteExtrasById: (id) =>
    cknex().delete()
    .from @SCYLLA_TABLES[3].name
    .where 'id', '=', id
    .run()
