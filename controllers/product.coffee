Promise = require 'bluebird'
_ = require 'lodash'

Product = require '../models/product'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.PRODUCT.NAME_KEBAB, EmbedService.TYPES.PRODUCT.ITEM
]

class ProductCtrl
  getById: ({id}, {user}) ->
    Product.getById id
    .then EmbedService.embed {embed: defaultEmbed}

  getAllByItemId: ({itemId}, {user}) ->
    Product.getAllByItemId itemId
    .map EmbedService.embed {embed: defaultEmbed}

module.exports = new ProductCtrl()
