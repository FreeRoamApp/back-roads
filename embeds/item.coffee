_ = require 'lodash'

Product = require '../models/product'

class ItemEmbed
  firstProductId: (item) ->
    Product.getFirstByItemId item.id
    .then (product) ->
      product?.id

module.exports = new ItemEmbed()
