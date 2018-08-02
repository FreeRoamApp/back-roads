_ = require 'lodash'

Item = require '../models/item'

class ProductEmbed
  nameKebab: (product) ->
    _.kebabCase product.name

  item: (product) ->
    Item.getById product.itemId

module.exports = new ProductEmbed()
