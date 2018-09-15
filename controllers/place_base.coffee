Promise = require 'bluebird'
_ = require 'lodash'

EmbedService = require '../services/embed'
config = require '../config'

module.exports = class PlaceBaseCtrl
  getBySlug: ({slug}, {user}) =>
    @Model.getBySlug slug
    .then (place) =>
      _.defaults {@type}, place
    # .then EmbedService.embed {embed: defaultEmbed}

  search: ({query}, {user}) =>
    @Model.search {query}
    .then (places) =>
      _.map places, (place) =>
        _.defaults {@type}, place
    # .then (results) ->
    #   Promise.map results, EmbedService.embed {embed: defaultEmbed}
