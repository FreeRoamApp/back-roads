Promise = require 'bluebird'
_ = require 'lodash'

Category = require '../models/category'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.CATEGORY.ITEM_NAMES]

class CategoryCtrl
  getAll: ({}, {user}) ->
    Category.getAll()
    .map EmbedService.embed {embed: defaultEmbed}


module.exports = new CategoryCtrl()
