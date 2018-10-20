_ = require 'lodash'
router = require 'exoid-router'
Joi = require 'joi'
geoip = require 'geoip-lite'

User = require '../models/user'
Partner = require '../models/partner'
EmbedService = require '../services/embed'
ImageService = require '../services/image'
CacheService = require '../services/cache'
config = require '../config'

AVATAR_SMALL_IMAGE_WIDTH = 96
AVATAR_SMALL_IMAGE_HEIGHT = 96
AVATAR_LARGE_IMAGE_WIDTH = 512
AVATAR_LARGE_IMAGE_HEIGHT = 512

defaultEmbed = [EmbedService.TYPES.USER.DATA]

class UserCtrl
  getMe: ({}, {user, headers, connection}) =>
    EmbedService.embed {embed: defaultEmbed}, user

  getCountry: ({}, {headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress
    # rendered via free-roam server (wrong ip)
    isServerSide = ip?.indexOf('::ffff:10.') isnt -1
    if isServerSide then null else geoip.lookup(ip)?.country?.toLowerCase()

  getById: ({id}) ->
    User.getById id
    .then User.sanitizePublic(null)

  getByUsername: ({username}) ->
    User.getByUsername username
    .then User.sanitizePublic(null)

  # problem: partner user account may not exist before partner link can.
  #
  getPartner: ({}, {user}) ->
    User.getPartnerSlugByUserId user.id
    .then (partnerSlug) ->
      if partnerSlug
        Partner.getBySlug partnerSlug
    .then (partner) ->
      _.defaults partner, {
          amazonAffiliateCode: config.AMAZON_AFFILIATE_CODE
      }

  setPartner: ({partner}, {user}) ->
    User.setPartner user.id, partner

  upsert: ({newUser}, {user}) ->
    User.upsert _.defaults newUser, {id: user.id}

  setAvatarImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {
        folder: 'uav'
        smallSize:
          width: AVATAR_SMALL_IMAGE_WIDTH, height: AVATAR_SMALL_IMAGE_HEIGHT
        largeSize:
          width: AVATAR_LARGE_IMAGE_WIDTH, height: AVATAR_LARGE_IMAGE_HEIGHT
        useMin: false
      }
    )
    .then (avatarImage) ->
      User.updateByUser user, {avatarImage: avatarImage}
    .then (response) ->
      key = "#{CacheService.PREFIXES.CHAT_USER}:#{user.id}"
      CacheService.deleteByKey key
      response
    .then ->
      User.getById user.id
  #
module.exports = new UserCtrl()
