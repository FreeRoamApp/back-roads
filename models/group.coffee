_ = require 'lodash'
uuid = require 'node-uuid'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
User = require './user'
GroupUser = require './group_user'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

defaultGroup = (group) ->
  unless group?
    return null

  group = _.defaults group, {
    uuid: cknex.getTimeUuid()
    id: null
    name: null
    description: null
    userUuid: null
    data:
      language: 'en'
  }

  group.data = JSON.stringify group.data

  group

defaultGroupOutput = (group) ->
  unless group?
    return null

  if group.data
    group.data = try
      JSON.parse group.data
    catch
      {}

  group

tables = [
  {
    name: 'groups_by_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      name: 'text'
      description: 'text'
      userUuid: 'uuid'
      data: 'text'
    primaryKey:
      partitionKey: ['uuid']
  }
  {
    name: 'groups_by_id'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      name: 'text'
      description: 'text'
      userUuid: 'uuid'
      data: 'text'
    primaryKey:
      partitionKey: ['id']
  }
]

class GroupModel
  SCYLLA_TABLES: tables

  upsert: (group) ->
    group = defaultGroup group

    Promise.all [
      cknex().update 'groups_by_uuid'
      .set _.omit group, ['uuid']
      .where 'uuid', '=', group.uuid
      .run()
      cknex().update 'groups_by_id'
      .set _.omit group, ['id']
      .where 'id', '=', group.id
      .run()
    ]

  getByUuid: (uuid) ->
    cknex().select '*'
    .from 'groups_by_uuid'
    .where 'uuid', '=', uuid
    .run {isSingle: true}
    .then defaultGroupOutput


  getById: (id) ->
    cknex().select '*'
    .from 'groups_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultGroupOutput

  # getAllByUuids: (ids, {limit} = {}) ->
  #   limit ?= 50
  #
  #   # TODO

  # getAll: ({filter, language, limit} = {}) ->
  #   # TODO
  #   limit ?= 10
  #
  #   q = r.table GROUPS_TABLE
  #
  #   if filter is 'public' and language
  #     q = q.getAll ['public', language], {index: TYPE_LANGUAGE_INDEX}
  #   else if filter is 'public'
  #     q = q.getAll ['public'], {index: TYPE_LANGUAGE_INDEX}
  #
  #   q.limit limit
  #   .run()
  #   .map defaultGroupOutput

  addUser: (groupUuid, userUuid) ->
    GroupUser.create {groupUuid, userUuid}
    .tap ->
      key = "#{CacheService.PREFIXES.GROUP_UUID}:#{groupUuid}"
      CacheService.deleteByKey key
      category = "#{CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY}:#{userUuid}"
      CacheService.deleteByCategory category

  removeUser: (groupUuid, userUuid) ->
    GroupUser.deleteByGroupUuidAndUserUuid groupUuid, userUuid
    .tap ->
      key = "#{CacheService.PREFIXES.GROUP_UUID}:#{groupUuid}"
      CacheService.deleteByKey key
      category = "#{CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY}:#{userUuid}"
      CacheService.deleteByCategory category

  deleteByUuid: (uuid) ->
    Promise.all [
      cknex().delete()
      .from 'groups_by_uuid'
      .where 'uuid', '=', uuid
      .run()

      cknex().delete()
      .from 'groups_by_id'
      .where 'id', '=', id
      .run()
    ]

module.exports = new GroupModel()
