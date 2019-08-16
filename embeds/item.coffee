_ = require 'lodash'

Product = require '../models/product'

class ItemEmbed
  productSlugs: (item, {filters} = {}) ->
    unless item
      return null
    Product.getSlugsByItemSlug item.slug, filters

module.exports = new ItemEmbed()
