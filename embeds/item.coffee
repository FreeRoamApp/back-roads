_ = require 'lodash'

Product = require '../models/product'

class ItemEmbed
  firstProductId: (item) ->
    unless item
      return null
    Product.getFirstByItemId item.id
    .then (product) ->
      product?.id

module.exports = new ItemEmbed()
