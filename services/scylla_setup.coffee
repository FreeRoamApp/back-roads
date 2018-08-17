Promise = require 'bluebird'
_ = require 'lodash'

CacheService = require './cache'
cknex = require './cknex'
config = require '../config'

# TODO

class ScyllaSetupService
  setup: (tables) =>
    CacheService.lock 'scylla_setup3', =>
      Promise.all [
        @createKeyspaceIfNotExists 'free_roam'
      ]
      .then =>
        if false and config.ENV is config.ENVS.DEV
          createTables = _.map _.filter(tables, ({name}) ->
            name in [
              'users_by_id'
            ]
          )
          Promise.each createTables, @createTableIfNotExist
        else
          Promise.each tables, @createTableIfNotExist
    , {expireSeconds: 300}

  createKeyspaceIfNotExists: (keyspaceName) ->
    # TODO
    ###
    CREATE KEYSPACE free_roam WITH replication = {
      'class': 'NetworkTopologyStrategy', 'datacenter1': '3'
    } AND durable_writes = true;
    ###
    Promise.resolve null

  createTableIfNotExist: (table) ->
    q = cknex(table.keyspace).createColumnFamilyIfNotExists table.name
    _.map table.fields, (type, key) ->
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

module.exports = new ScyllaSetupService()
