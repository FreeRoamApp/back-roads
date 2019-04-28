_ = require 'lodash'
Promise = require 'bluebird'

cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
StreamService = require '../services/stream'

# TODO: handle item (items_by_category), conversation (1 per userId)

module.exports = class Base
  batchUpsert: (rows) =>
    Promise.map rows, (row) =>
      @upsert row

  batchIndex: (rows) =>
    Promise.map rows, (row) =>
      @index row

  # use this whenever possible over @upsert since it'll handle changing primary
  # key values without creating duplicates. eg changing username will delete
  # old row in users_by_username and create a new one w/ new username
  # MAKE SURE to send full existingRow if doing that...so it all gets copied
  # TODO: go through old code and make sure this is used in favor of
  # _.defaults with the primary keys manually spec'd
  upsertByRow: (row, diff, options) =>
    keyColumns = _.filter _.uniq _.flatten _.map @getScyllaTables(), (table) ->
      table.primaryKey.partitionKey.concat(
        table.primaryKey.clusteringColumns
      )
    primaryKeyValues = _.pick row, keyColumns
    newPrimaryKeyValues = _.pick diff, keyColumns

    # any primary keys that are being changed, so we can delete & recreate
    changedPrimaryKeys = _.filter keyColumns, (key) ->
      newPrimaryKeyValues[key]? and
        newPrimaryKeyValues[key] isnt primaryKeyValues[key]

    @upsert(
      _.defaults(diff, primaryKeyValues)
      _.defaults options, {skipDefaults: true}
    )
    .tap =>
      # delete any rows where the primary key changed
      if row
        Promise.each changedPrimaryKeys, (key) =>
          tablesWithKey = _.filter @getScyllaTables(), (table) =>
            table.primaryKey.partitionKey.concat(
              table.primaryKey.clusteringColumns
            ).indexOf(key) isnt -1

          Promise.each tablesWithKey, (table) =>
            @_deleteScyllaRowByTableAndRow table, row


  upsert: (row, options = {}) =>
    {ttl, prepareFn, isUpdate, add, remove, skipDefaults} = options

    scyllaRow = if skipDefaults then row else @defaultInput row
    elasticSearchRow = _.defaults {id: scyllaRow.id}, row

    Promise.all _.filter _.map(@getScyllaTables(), (table) ->
      if table.ignoreUpsert
        return
      scyllaTableRow = _.pick scyllaRow, _.keys table.fields

      keyColumns = _.filter table.primaryKey.partitionKey.concat(
        table.primaryKey.clusteringColumns
      )

      if missing = _.find(keyColumns, (column) -> not scyllaTableRow[column])
        return console.log "missing #{missing} in #{table.name} upsert"


      set = _.omit scyllaTableRow, keyColumns
      q = cknex().update table.name
      .set set
      _.forEach keyColumns, (column) ->
        q.andWhere column, '=', scyllaTableRow[column]
      if ttl
        q.usingTTL ttl
      if add
        q.add add
      if remove
        q.remove remove
      q.run()
    ).concat [@index elasticSearchRow]
    .then =>
      if @streamChannelKey
        (if prepareFn
        then prepareFn(scyllaRow)
        else Promise.resolve scyllaRow)
        .then (scyllaRow) =>
          unless isUpdate
            @streamCreate scyllaRow
          @defaultOutput scyllaRow
      else
        @defaultOutput scyllaRow

  index: (row) =>
    if _.isEmpty @getElasticSearchIndices?()
      Promise.resolve()
    else
      row = @defaultESInput row
      elasticsearch.update {
        index: @getElasticSearchIndices?()[0].name
        type: @getElasticSearchIndices?()[0].name
        id: row.id
        body:
          doc:
            _.pick row, _.keys @getElasticSearchIndices?()[0].mappings
          doc_as_upsert: true
      }
      .catch (err) =>
        console.log 'elastic err', @getElasticSearchIndices?()[0].name, err
        throw err

  # parts of row -> full row
  getByRow: (row) =>
    scyllaRow = @defaultInput row
    table = @getScyllaTables()[0]
    keyColumns = _.filter table.primaryKey.partitionKey.concat(
      table.primaryKey.clusteringColumns
    )
    q = cknex().select '*'
    .from table.name
    _.forEach keyColumns, (column) ->
      q.andWhere column, '=', scyllaRow[column]
    q.run {isSingle: true}

  _deleteScyllaRowByTableAndRow: (table, row) =>
    scyllaRow = @defaultInput row

    if table.ignoreUpsert
      return
    keyColumns = _.filter table.primaryKey.partitionKey.concat(
      table.primaryKey.clusteringColumns
    )
    q = cknex().delete()
    .from table.name
    _.forEach keyColumns, (column) ->
      q.andWhere column, '=', scyllaRow[column]
    q.run()

  deleteByRow: (row) =>
    Promise.all _.filter _.map(@getScyllaTables(), (table) =>
      @_deleteScyllaRowByTableAndRow table, row
    ).concat [@deleteESById row.id]
    .then =>
      if @streamChannelKey
        @streamDeleteById row.id, row
      null

  deleteESById: (id) =>
    if _.isEmpty @getElasticSearchIndices?()
      Promise.resolve()
    else
      elasticsearch.delete {
        index: @getElasticSearchIndices?()[0].name
        type: @getElasticSearchIndices?()[0].name
        id: "#{id}"
      }
      .catch (err) ->
        console.log 'elastic err', err

  defaultInput: (row) -> row
  defaultOutput: (row) -> row
  defaultESInput: (row) ->
    if row.id
      row.id = "#{row.id}"
    row
  defaultESOutput: (row) -> row

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
