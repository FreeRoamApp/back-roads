_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
config = require '../config'
cknex = require '../services/cknex'

ONE_DAY_SECONDS = 3600 * 24
THREE_HOURS_SECONDS = 3600 * 3
SIXTY_DAYS_SECONDS = 60 * 3600 * 24

class PartnerModel extends Base
  SCYLLA_TABLES: [
    {
      name: 'partners_by_userId'
      keyspace: 'free_roam'
      fields:
        userId: 'timeuuid'
        slug: 'text'
        name: 'text'
        amazonAffiliateCode: 'text'
      primaryKey:
        partitionKey: ['userId']
    }
    {
      name: 'partners_by_slug'
      keyspace: 'free_roam'
      fields:
        userId: 'timeuuid'
        slug: 'text'
        name: 'text'
        amazonAffiliateCode: 'text'
      primaryKey:
        partitionKey: ['slug']
    }
  ]

  getByUserId: (userId) ->
    cknex().select '*'
    .from 'partners_by_userId'
    .where 'userId', '=', userId
    .run {isSingle: true}

  getBySlug: (slug) ->
    cknex().select '*'
    .from 'partners_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}

  defaultInput: (partner) ->
    unless partner?
      return null

    _.defaults partner, {
    }

module.exports = new PartnerModel()
