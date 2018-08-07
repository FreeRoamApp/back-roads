Promise = require 'bluebird'
_ = require 'lodash'

Category = require '../models/category'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.CATEGORY.FIRST_ITEM_PRODUCT_ID]

class CategoryCtrl
  getAll: ({}, {user}) ->
    Category.getAll()
    .map EmbedService.embed {embed: defaultEmbed}


module.exports = new CategoryCtrl()
