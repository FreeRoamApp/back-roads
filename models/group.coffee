_ = require 'lodash'
uuid = require 'node-uuid'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
User = require './user'
GroupUser = require './group_user'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

class GroupModel extends Base
  SCYLLA_TABLES: [
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

  getById: (id) =>
    cknex().select '*'
    .from 'groups_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then @defaultOutput


  getBySlug: (slug) =>
    cknex().select '*'
    .from 'groups_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then @defaultOutput

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

  defaultInput: (group) ->
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

  defaultOutput: (group) ->
    unless group?
      return null

    if group.data
      group.data = try
        JSON.parse group.data
      catch
        {}

    group

module.exports = new GroupModel()
