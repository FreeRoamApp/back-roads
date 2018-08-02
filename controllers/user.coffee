_ = require 'lodash'
router = require 'exoid-router'
Joi = require 'joi'
geoip = require 'geoip-lite'

User = require '../models/user'
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

  upsert: ({newUser}, {user}) ->
    null # TODO
  #
  # setAvatarImage: ({}, {user, file}) ->
  #   router.assert {file}, {
  #     file: Joi.object().unknown().keys schemas.imageFile
  #   }
  #
  #   # bust cache
  #   keyPrefix = "images/freeroam/u/#{user.id}/avatar_#{Date.now()}"
  #
  #   Promise.all [
  #     ImageService.uploadImage
  #       key: "#{keyPrefix}.original.jpg"
  #       stream: ImageService.toStream
  #         buffer: file.buffer
  #         quality: 100
  #
  #     ImageService.uploadImage
  #       key: "#{keyPrefix}.small.jpg"
  #       stream: ImageService.toStream
  #         buffer: file.buffer
  #         width: AVATAR_SMALL_IMAGE_WIDTH
  #         height: AVATAR_SMALL_IMAGE_HEIGHT
  #
  #     ImageService.uploadImage
  #       key: "#{keyPrefix}.large.jpg"
  #       stream: ImageService.toStream
  #         buffer: file.buffer
  #         width: AVATAR_LARGE_IMAGE_WIDTH
  #         height: AVATAR_LARGE_IMAGE_HEIGHT
  #   ]
  #   .then (imageKeys) ->
  #     _.map imageKeys, (imageKey) ->
  #       "https://#{config.CDN_HOST}/#{imageKey}"
  #   .then ([originalUrl, smallUrl, largeUrl]) ->
  #     avatarImage =
  #       originalUrl: originalUrl
  #       versions: [
  #         {
  #           width: AVATAR_SMALL_IMAGE_WIDTH
  #           height: AVATAR_SMALL_IMAGE_HEIGHT
  #           url: smallUrl
  #         }
  #         {
  #           width: AVATAR_LARGE_IMAGE_WIDTH
  #           height: AVATAR_LARGE_IMAGE_HEIGHT
  #           url: largeUrl
  #         }
  #       ]
  #     User.updateById user.id, {avatarImage: avatarImage}
  #   .then (response) ->
  #     key = "#{CacheService.PREFIXES.CHAT_USER}:#{user.id}"
  #     CacheService.deleteByKey key
  #     response
  #   .then ->
  #     User.getById user.id
  #   .then User.sanitize(user.id)

module.exports = new UserCtrl()
