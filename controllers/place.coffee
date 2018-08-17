Promise = require 'bluebird'
_ = require 'lodash'

Place = require '../models/place'
EmbedService = require '../services/embed'
config = require '../config'

class PlaceCtrl
  getBySlug: ({slug}, {user}) ->
    Place.getBySlug slug
    # .then EmbedService.embed {embed: defaultEmbed}

  search: ({query}, {user}) ->
    Place.search {query}
    # .then (results) ->
    #   Promise.map results, EmbedService.embed {embed: defaultEmbed}


module.exports = new PlaceCtrl()
