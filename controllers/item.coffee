Promise = require 'bluebird'
_ = require 'lodash'

Item = require '../models/item'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.ITEM.FIRST_PRODUCT_ID]

class ItemCtrl
  getById: ({id}, {user}) ->
    Item.getById id
    .then EmbedService.embed {embed: defaultEmbed}

  getAll: ({}, {user}) ->
    Item.getAll()
    .map EmbedService.embed {embed: defaultEmbed}

  getAllByCategory: ({category}, {user}) ->
    Item.getAllByCategory category
    .map EmbedService.embed {embed: defaultEmbed}


module.exports = new ItemCtrl()
