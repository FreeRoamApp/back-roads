_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'

Base = require './base'
config = require '../config'
cknex = require '../services/cknex'

ONE_DAY_SECONDS = 3600 * 24
THREE_HOURS_SECONDS = 3600 * 3
SIXTY_DAYS_SECONDS = 60 * 3600 * 24

# insert into free_roam.partners_by_slug (slug,"amazonAffiliateCode") values ('heathandalyssa', 'alyssapacom0b-20')

scyllaFields =
  userId: 'timeuuid'
  slug: 'text'
  name: 'text'
  amazonAffiliateCode: 'text'

class PartnerModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'partners_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
      }
      {
        name: 'partners_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
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

module.exports = new PartnerModel()
