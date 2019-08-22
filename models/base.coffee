_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'
StreamService = require '../services/stream'

# TODO: handle item (items_by_category), conversation (1 per userId)

module.exports = class Base
  constructor: ->
    @fieldsWithType = _.reduce @getScyllaTables(), (obj, table) ->
      _.forEach table.fields, (value, key) ->
        obj[key] = {
          type: value?.type or value
          defaultFn: value?.defaultFn
        }
      obj
    , {}

    @fieldsWithDefaultFn = _.pickBy @fieldsWithType, ({type, defaultFn}, key) ->
      defaultFn or (key is 'id' and type in ['uuid', 'timeuuid'])

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
  upsertByRow: (row, diff, options = {}) =>
    keyColumns = _.filter _.uniq _.flatten _.map @getScyllaTables(), (table) ->
      table.primaryKey.partitionKey.concat(
        table.primaryKey.clusteringColumns
      )
    primaryKeyValues = _.pick row, keyColumns
    newPrimaryKeyValues = _.pick diff, keyColumns

    # any primary keys that are being changed, so we can delete & recreate
    changedPrimaryKeys = _.filter keyColumns, (key) ->
      newPrimaryKeyValues[key]? and primaryKeyValues[key]? and
        "#{newPrimaryKeyValues[key]}" isnt "#{primaryKeyValues[key]}"

    @upsert(
      _.defaults(diff, primaryKeyValues)
      _.defaults options, {skipAdditions: Boolean row}
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
            .then (deletedRow) =>
              # transfer over any other info the row we're deleting had
              if deletedRow
                row = _.defaults(diff, deletedRow)
                scyllaRow = @defaultInput row
                @_upsertScyllaRowByTableAndRow table, scyllaRow


  upsert: (row, options = {}) =>
    {prepareFn, isUpdate, skipAdditions} = options

    scyllaRow = @defaultInput row, {skipAdditions}
    elasticSearchRow = _.defaults {id: scyllaRow.id}, row

    Promise.all _.filter _.map(@getScyllaTables(), (table) =>
      if table.ignoreUpsert
        return
      @_upsertScyllaRowByTableAndRow table, scyllaRow, options
    ).concat [@index elasticSearchRow]
    .tap =>
      @clearCacheByRow? scyllaRow
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

  _upsertScyllaRowByTableAndRow: (table, scyllaRow, options = {}) ->
    {ttl, add, remove} = options

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

  # returns row that was deleted
  _deleteScyllaRowByTableAndRow: (table, row) =>
    scyllaRow = @defaultInput row

    if table.ignoreUpsert
      return
    keyColumns = _.filter table.primaryKey.partitionKey.concat(
      table.primaryKey.clusteringColumns
    )
    q = cknex().select '*'
    .from table.name
    _.forEach keyColumns, (column) ->
      q.andWhere column, '=', scyllaRow[column]
    q.run({isSingle: true}).tap ->
      q = cknex().delete()
      .from table.name
      _.forEach keyColumns, (column) ->
        q.andWhere column, '=', scyllaRow[column]
      q.run()

  deleteByRow: (row) =>
    Promise.all _.filter _.map(@getScyllaTables(), (table) =>
      @_deleteScyllaRowByTableAndRow table, row
    ).concat [@deleteESById row.id]
    .tap =>
      @clearCacheByRow? row
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

  defaultInput: (row, {skipAdditions} = {}) =>
    unless skipAdditions
      _.map @fieldsWithDefaultFn, (field, key) ->
        value = row[key]
        if not value and not skipAdditions and field.defaultFn
          row[key] = field.defaultFn()
        else if not value and not skipAdditions and field.type is 'uuid'
          row[key] = cknex.getUuid()
        else if not value and not skipAdditions and field.type is 'timeuuid'
          row[key] = cknex.getTimeUuid()
    _.mapValues row, (value, key) =>
      {type} = @fieldsWithType[key] or {}

      if type is 'json'
        JSON.stringify value
      # else if type is 'timeuuid' and typeof value is 'string'
      #   row[key] = cknex.getTimeUuidFromString(value)
      # else if type is 'uuid' and typeof value is 'string'
      #   row[key] = cknex.getUuidFromString(value)
      else
        value

  defaultOutput: (row) =>
    unless row?
      return null

    _.mapValues row, (value, key) =>
      {type, defaultFn} = @fieldsWithType[key] or {}
      if type is 'json' and value and typeof value is 'object'
        value
      else if type is 'json' and value
        try
          JSON.parse value
        catch
          defaultFn?() or {}
      else if type is 'json'
        defaultFn?() or {}
      else if value and type in ['uuid', 'timeuuid']
        "#{value}"
      else
        value

  defaultESInput: (row) =>
    if row.id
      row.id = "#{row.id}"
    _.mapValues row, (value, key) =>
      {type} = @fieldsWithType[key] or {}

      if type is 'json' and typeof value is 'string'
        JSON.parse value
      else
        value

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
