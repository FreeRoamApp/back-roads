_ = require 'lodash'

Item = require '../models/item'
ItemEmbed = require '../embeds/item'

class CategoryEmbed
  itemNames: (category) ->
    Item.getNamesByCategory category.slug

module.exports = new CategoryEmbed()
