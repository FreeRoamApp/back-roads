_ = require 'lodash'
router = require 'exoid-router'
Joi = require 'joi'
geoip = require 'geoip-lite'
bcrypt = require 'bcrypt-nodejs'
Promise = require 'bluebird'

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

defaultEmbed = [EmbedService.TYPES.USER.KARMA]

class UserCtrl
  getMe: ({}, {user, headers, connection}) ->
    EmbedService.embed {embed: defaultEmbed}, user
    .then User.sanitizePrivate(null)

  getCountry: ({}, {headers, connection}) ->
    ip = headers['x-forwarded-for'] or
          connection.remoteAddress
    # rendered via free-roam server (wrong ip)
    isServerSide = ip?.indexOf('::ffff:10.') isnt -1
    if isServerSide then null else geoip.lookup(ip)?.country?.toLowerCase()

  getById: ({id}) ->
    User.getById id
    .then EmbedService.embed {embed: defaultEmbed}
    .then User.sanitizePublic(null)

  getByUsername: ({username}) ->
    User.getByUsername username
    .then EmbedService.embed {embed: defaultEmbed}
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

  _uploadAvatar: (userId, file) ->
    ImageService.uploadImageByUserIdAndFile(
      userId, file, {
        folder: 'uav'
        smallSize:
          width: AVATAR_SMALL_IMAGE_WIDTH, height: AVATAR_SMALL_IMAGE_HEIGHT
        largeSize:
          width: AVATAR_LARGE_IMAGE_WIDTH, height: AVATAR_LARGE_IMAGE_HEIGHT
        useMin: false
      }
    )

  search: ({query, sort, limit}, {user}) ->
    User.search {query, sort, limit}
    .then ({users}) ->
      users

  upsert: ({userDiff}, {user, file}) =>
    currentInsecurePassword = userDiff.currentPassword
    newInsecurePassword = userDiff.password
    if userDiff.username
      userDiff.username = userDiff.username.toLowerCase()
    username = userDiff.username
    userDiff = _.pick userDiff, ['username', 'links', 'bio', 'name']

    if userDiff.links?.instagram and userDiff.links.instagram.indexOf('instagram.com') is -1
      if userDiff.links.instagram.indexOf('@') isnt -1
        userDiff.links.instagram = userDiff.links.instagram.replace '@', ''
      userDiff.links.instagram = "https://instagram.com/#{userDiff.links.instagram}"

    valid = Joi.validate {username, password: newInsecurePassword}, {
      password: Joi.string().min(6).max(1000)
      email: Joi.string().email().allow('')
      username: Joi.string().min(1).max(100).allow(null)
                .regex /^[a-zA-Z0-9-_]+$/
    }

    if valid.error
      errorField = valid.error.details[0].path
      info = switch errorField
        when 'username' then 'error.invalidUsername'
        when 'password' then 'error.invalidPassword'
        when 'email' then 'error.invalidEmail'
        else 'error.invalid'
      router.throw {
        status: 400
        info:
          langKey: info
          field: errorField
        ignoreLog: true
      }

    Promise.all [
      if file
        @_uploadAvatar user.id, file
      else
        Promise.resolve null

      if newInsecurePassword
        Promise.promisify(bcrypt.compare)(
          currentInsecurePassword
          user.password
        )
        .then (success) ->
          unless success
            router.throw {
              status: 400
              info:
                langKey: 'error.invalidCurrentPassword'
                field: 'currentPassword'
              ignoreLog: true
            }
          Promise.promisify(bcrypt.hash)(
            newInsecurePassword, bcrypt.genSaltSync(config.BCRYPT_ROUNDS), null
          )
      else
        Promise.resolve null
    ]
    .then ([avatarImage, password]) ->
      if password
        userDiff.password = password

      if avatarImage
        userDiff.avatarImage = JSON.stringify avatarImage

      User.upsertByRow user, userDiff
      .then (response) ->
        key = "#{CacheService.PREFIXES.CHAT_USER}:#{user.id}"
        CacheService.deleteByKey key
        response
      .then ->
        User.getById user.id

  #
module.exports = new UserCtrl()
