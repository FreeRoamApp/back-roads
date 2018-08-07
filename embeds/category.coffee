_ = require 'lodash'

Item = require '../models/item'
ItemEmbed = require '../embeds/item'

class CategoryEmbed
  firstItemFirstProductId: (category) ->
    Item.getFirstByCategory category.id
    .then ItemEmbed.firstProductId

module.exports = new CategoryEmbed()
