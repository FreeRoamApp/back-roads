_ = require 'lodash'

Product = require '../models/product'

class ItemEmbed
  firstProductSlug: (item) ->
    unless item
      return null
    Product.getFirstByItemSlug item.slug
    .then (product) ->
      product?.slug

module.exports = new ItemEmbed()
