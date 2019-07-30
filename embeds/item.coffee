_ = require 'lodash'

Product = require '../models/product'

class ItemEmbed
  productSlugs: (item) ->
    unless item
      return null
    Product.getSlugsByItemSlug item.slug

module.exports = new ItemEmbed()
