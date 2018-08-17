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
    id: cknex.getTimeUuid()
    id: null
    name: null
    description: null
    userId: null
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
    name: 'groups_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      slug: 'text'
      name: 'text'
      description: 'text'
      userId: 'uuid'
      data: 'text'
    primaryKey:
      partitionKey: ['id']
  }
  {
    name: 'groups_by_slug'
    keyspace: 'free_roam'
    fields:
      id: 'timeuuid'
      slug: 'text'
      name: 'text'
      description: 'text'
      userId: 'uuid'
      data: 'text'
    primaryKey:
      partitionKey: ['slug']
  }
]

class GroupModel
  SCYLLA_TABLES: tables

  upsert: (group) ->
    group = defaultGroup group

    Promise.all [
      cknex().update 'groups_by_id'
      .set _.omit group, ['id']
      .where 'id', '=', group.id
      .run()
      cknex().update 'groups_by_slug'
      .set _.omit group, ['slug']
      .where 'slug', '=', group.slug
      .run()
    ]

  getById: (id) ->
    cknex().select '*'
    .from 'groups_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultGroupOutput


  getBySlug: (slug) ->
    cknex().select '*'
    .from 'groups_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then defaultGroupOutput

  # getAllByIds: (ids, {limit} = {}) ->
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

  addUser: (groupId, userId) ->
    GroupUser.create {groupId, userId}
    .tap ->
      key = "#{CacheService.PREFIXES.GROUP_ID}:#{groupId}"
      CacheService.deleteByKey key
      category = "#{CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY}:#{userId}"
      CacheService.deleteByCategory category

  removeUser: (groupId, userId) ->
    GroupUser.deleteByGroupIdAndUserId groupId, userId
    .tap ->
      key = "#{CacheService.PREFIXES.GROUP_ID}:#{groupId}"
      CacheService.deleteByKey key
      category = "#{CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY}:#{userId}"
      CacheService.deleteByCategory category

  deleteById: (id) ->
    Promise.all [
      cknex().delete()
      .from 'groups_by_id'
      .where 'id', '=', id
      .run()

      cknex().delete()
      .from 'groups_by_slug'
      .where 'slug', '=', slug
      .run()
    ]

module.exports = new GroupModel()
