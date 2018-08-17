Promise = require 'bluebird'
_ = require 'lodash'

Item = require '../models/item'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.ITEM.FIRST_PRODUCT_SLUG]

class ItemCtrl
  getBySlug: ({slug}, {user}) ->
    Item.getBySlug slug
    .then EmbedService.embed {embed: defaultEmbed}

  getAll: ({}, {user}) ->
    Item.getAll()
    .map EmbedService.embed {embed: defaultEmbed}

  getAllByCategory: ({category}, {user}) ->
    Item.getAllByCategory category
    .map EmbedService.embed {embed: defaultEmbed}

  search: ({query}, {user}) ->
    Item.search {query}
    .then (results) ->
      Promise.map results, EmbedService.embed {embed: defaultEmbed}


module.exports = new ItemCtrl()
