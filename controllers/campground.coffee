Promise = require 'bluebird'
_ = require 'lodash'

Campground = require '../models/campground'
EmbedService = require '../services/embed'
config = require '../config'

class CampgroundCtrl
  getBySlug: ({slug}, {user}) ->
    Campground.getBySlug slug
    # .then EmbedService.embed {embed: defaultEmbed}

  search: ({query}, {user}) ->
    Campground.search {query}
    # .then (results) ->
    #   Promise.map results, EmbedService.embed {embed: defaultEmbed}


module.exports = new CampgroundCtrl()
