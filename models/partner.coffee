_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

config = require '../config'
cknex = require '../services/cknex'

ONE_DAY_SECONDS = 3600 * 24
THREE_HOURS_SECONDS = 3600 * 3
SIXTY_DAYS_SECONDS = 60 * 3600 * 24

defaultPartner = (partner) ->
  unless partner?
    return null

  _.defaults partner, {
  }


tables = [
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

class PartnerModel
  SCYLLA_TABLES: tables

  upsert: (partner) ->
    partner = defaultPartner partner

    Promise.all [
      cknex().update 'partners_by_userId'
      .set _.omit partner, ['userId']
      .where 'userId', '=', partner.userId
      .run()

      cknex().update 'partners_by_slug'
      .set _.omit partner, ['slug']
      .where 'slug', '=', partner.slug
      .run()
    ]
      .then ->
        partner

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

module.exports = new PartnerModel()
