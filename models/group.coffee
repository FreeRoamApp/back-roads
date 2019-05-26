_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
User = require './user'
GroupUser = require './group_user'
config = require '../config'

ONE_DAY_SECONDS = 3600 * 24
ONE_HOUR_SECONDS = 3600

scyllaFields =
  id: 'timeuuid'
  slug: 'text'
  name: 'text'
  description: 'text'
  userId: 'uuid'
  data: {type: 'json', defaultFn: -> {language: 'en'}}

class GroupModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'groups_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
      {
        name: 'groups_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
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

  getAllByIds: (ids, {limit} = {}) ->
    limit ?= 50

    cknex().select '*'
    .from 'groups_by_id'
    .where 'id', 'in', ids
    .run()
    .map @defaultOutput

  getAll: ({filter, language, limit} = {}) ->
    @getBySlug 'boondocking'
    .then (group) ->
      [group]
    # TODO
    # limit ?= 10
    #
    # q = r.table GROUPS_TABLE
    #
    # if filter is 'public' and language
    #   q = q.getAll ['public', language], {index: TYPE_LANGUAGE_INDEX}
    # else if filter is 'public'
    #   q = q.getAll ['public'], {index: TYPE_LANGUAGE_INDEX}
    #
    # q.limit limit
    # .run()
    # .map defaultGroupOutput

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
