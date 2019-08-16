Promise = require 'bluebird'
_ = require 'lodash'

Product = require '../models/product'
UserData = require '../models/user_data'
UserRig = require '../models/user_rig'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.PRODUCT.NAME_KEBAB, EmbedService.TYPES.PRODUCT.ITEM
]

class ProductCtrl
  getBySlug: ({slug}, {user}) ->
    Product.getBySlug slug
    .then EmbedService.embed {embed: defaultEmbed}

  getAllByItemSlug: ({itemSlug}, {user}) ->
    Promise.all [
      UserData.getByUserId user.id
      UserRig.getByUserId user.id
    ]
    .then ([userData, userRig]) ->
      filters = {
        rig: userRig?.type
        experience: userData?.experience
        hookupPreference: userData?.hookupPreference
      }
      Product.getAllByItemSlug itemSlug, filters
      .map EmbedService.embed {embed: defaultEmbed}

module.exports = new ProductCtrl()
