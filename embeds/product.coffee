_ = require 'lodash'

Item = require '../models/item'

class ProductEmbed
  nameKebab: (product) ->
    _.kebabCase product.name

  item: (product) ->
    Item.getBySlug product.itemSlug

module.exports = new ProductEmbed()
