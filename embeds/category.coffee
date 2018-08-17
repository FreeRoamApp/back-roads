_ = require 'lodash'

Item = require '../models/item'
ItemEmbed = require '../embeds/item'

class CategoryEmbed
  firstItemFirstProductSlug: (category) ->
    Item.getFirstByCategory category.slug
    .then ItemEmbed.firstProductSlug

module.exports = new CategoryEmbed()
