_ = require 'lodash'
Promise = require 'bluebird'

cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
StreamService = require '../services/stream'

# TODO: handle item (items_by_category)

module.exports = class Base
  batchUpsert: (rows) =>
    Promise.map rows, (row) =>
      @upsert row

  upsert: (row, {ttl, prepareFn, isUpdate, map} = {}) =>
    scyllaRow = @defaultInput row

    Promise.all _.filter _.map(@SCYLLA_TABLES, (table) ->
      if table.ignoreUpsert
        return
      keyColumns = _.filter table.primaryKey.partitionKey.concat(
        table.primaryKey.clusteringColumns
      )

      if missing = _.find(keyColumns, (column) -> not scyllaRow[column])
        return console.log "missing #{missing} in #{table.name} upsert"

      set = _.omit scyllaRow, keyColumns
      q = cknex().update table.name
      .set set
      _.forEach keyColumns, (column) ->
        q.andWhere column, '=', scyllaRow[column]
      if ttl
        q.usingTTL ttl
      if map
        _.forEach map, (value, column) ->
          q.add column, value
      q.run()
    ).concat [@index row]
    .then =>
      if @streamChannelKey
        prepareFn?(scyllaRow) or Promise.resolve scyllaRow
        .then (scyllaRow) =>
          unless isUpdate
            @streamCreate scyllaRow
          scyllaRow
      else
        scyllaRow

  index: (row) =>
    if _.isEmpty @ELASTICSEARCH_INDICES
      Promise.resolve()
    else
      row = @defaultESInput row
      elasticsearch.index {
        index: @ELASTICSEARCH_INDICES[0].name
        type: @ELASTICSEARCH_INDICES[0].name
        id: row.slug
        body: _.pick row, _.keys @ELASTICSEARCH_INDICES[0].mappings
      }

  defaultInput: (row) -> row
  defaultOutput: (row) -> row
  defaultESInput: (row) -> row

  # streaming fns
  streamCreate: (obj) =>
    channels = _.map @streamChannelsBy, (channelBy) =>
      channelById = obj[channelBy]
      "#{@streamChannelKey}:#{channelBy}:#{channelById}"
    StreamService.create obj, channels

  streamUpdateById: (id, obj) =>
    channels = _.map @streamChannelsBy, (channelBy) =>
      channelById = obj?[channelBy]
      "#{@streamChannelKey}:#{channelBy}:#{channelById}"
    StreamService.updateById id, obj, channels

  streamDeleteById: (id, obj) =>
    channels = _.map @streamChannelsBy, (channelBy) =>
      channelById = obj?[channelBy]
      "#{@streamChannelKey}:#{channelBy}:#{channelById}"
    StreamService.deleteById id, channels

  stream: (options) =>
    {emit, socket, route, channelBy, channelById,
      initial, initialPostFn, postFn} = options
    StreamService.stream {
      channel: "#{@streamChannelKey}:#{channelBy}:#{channelById}"
      emit
      socket
      route
      initial: initial.map (initialPostFn or _.identity)
      postFn
    }

  unsubscribe: ({socket, channelBy, channelById}) =>
    StreamService.unsubscribe {
      channel: "#{@streamChannelKey}:#{channelBy}:#{channelById}"
      socket
    }
