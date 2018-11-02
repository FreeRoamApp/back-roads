Promise = require 'bluebird'
_ = require 'lodash'

CacheService = require './cache'
cknex = require './cknex'
config = require '../config'

# TODO

class ScyllaSetupService
  setup: (tables) =>
    CacheService.lock 'scylla_setup4', =>
      Promise.all [
        @createKeyspaceIfNotExists 'free_roam'
      ]
      .then =>
        if true and config.ENV is config.ENVS.DEV
          createTables = _.map _.filter(tables, ({name}) ->
            name.indexOf('reviewless') isnt -1
          )
          Promise.each createTables, @createTableIfNotExist
        else
          Promise.each tables, @createTableIfNotExist
      .then ->
        cknex.enableErrors()
    , {expireSeconds: 300}

  createKeyspaceIfNotExists: (keyspaceName) ->
    # TODO
    ###
    CREATE KEYSPACE free_roam WITH replication = {
      'class': 'NetworkTopologyStrategy', 'datacenter1': '3'
    } AND durable_writes = true;
    ###
    Promise.resolve null

  addColumnToQuery: (q, type, key) ->
    if typeof type is 'object'
      if type.subType2
        q[type.type] key, type.subType, type.subType2
      else
        q[type.type] key, type.subType
    else
      try
        q[type] key
      catch err
        console.log key
        throw err

  createTableIfNotExist: (table) =>
    console.log 'create', table.name
    primaryColumns = _.filter(
      table.primaryKey.partitionKey.concat(table.primaryKey.clusteringColumns)
    )
    {primaryFields, normalFields} = _.reduce table.fields, (obj, type, key) ->
      if key in primaryColumns
        obj.primaryFields.push {key, type}
      else
        obj.normalFields.push {key, type}
      obj
    , {primaryFields: [], normalFields: []}

    # add primary fields, set as primary, set order
    q = cknex(table.keyspace).createColumnFamilyIfNotExists table.name

    _.map primaryFields, ({key, type}) =>
      @addColumnToQuery q, type, key

    if table.primaryKey.clusteringColumns
      q.primary(
        table.primaryKey.partitionKey, table.primaryKey.clusteringColumns
      )
    else
      q.primary table.primaryKey.partitionKey

    if table.withClusteringOrderBy
      unless _.isArray table.withClusteringOrderBy[0]
        table.withClusteringOrderBy = [table.withClusteringOrderBy]
      _.map table.withClusteringOrderBy, (orderBy) ->
        q.withClusteringOrderBy(
          orderBy[0]
          orderBy[1]
        )

    q.run()
    .then =>

      # add any new columns
      Promise.each normalFields, ({key, type}) =>
        q = cknex(table.keyspace).alterColumnFamily(table.name)
        @addColumnToQuery q, type, key
        q.run().catch -> null

module.exports = new ScyllaSetupService()
