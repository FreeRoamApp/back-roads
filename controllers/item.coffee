Promise = require 'bluebird'
_ = require 'lodash'

Item = require '../models/item'
UserData = require '../models/user_data'
UserRig = require '../models/user_rig'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.ITEM.PRODUCT_SLUGS]

class ItemCtrl
  getBySlug: ({slug}, {user}) ->
    Item.getBySlug slug
    .then EmbedService.embed {embed: defaultEmbed}

  getAll: ({}, {user}) ->
    Item.getAll()
    .map EmbedService.embed {embed: defaultEmbed}

  getAllByCategory: ({category}, {user}) ->
    Promise.all [
      UserData.getByUserId user.id
      UserRig.getByUserId user.id
    ]
    .then ([userData, userRig]) ->
      filters = {
        rig: userRig?.type
        experience: userData?.experience
        hookupPreference: userData?.hookupPreference
      }
      Item.getAllByCategory category, filters
      .map EmbedService.embed {embed: defaultEmbed, options: {filters}}

  search: ({query}, {user}) ->
    Item.search {query}
    .then (results) ->
      Promise.map results, EmbedService.embed {embed: defaultEmbed}


module.exports = new ItemCtrl()
