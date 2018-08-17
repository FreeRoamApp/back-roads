Promise = require 'bluebird'
_ = require 'lodash'

Product = require '../models/product'
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
    Product.getAllByItemSlug itemSlug
    .map EmbedService.embed {embed: defaultEmbed}

module.exports = new ProductCtrl()
