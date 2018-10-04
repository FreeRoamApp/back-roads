Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

EmbedService = require '../services/embed'
GeocoderService = require '../services/geocoder'
config = require '../config'

MAX_UNIQUE_ID_ATTEMPTS = 10
COORDINATE_REGEX_STR = '(^[-+]?(?:[1-8]?\\d(?:\\.\\d+)?|90(?:\\.0+)?))\\s*,\\s*([-+]?(?:180(?:\\.0+)?|(?:(?:1[0-7]\\d)|(?:[1-9]?\\d))(?:\\.\\d+)?))$'

module.exports = class PlaceBaseCtrl
  getBySlug: ({slug}, {user}) =>
    @Model.getBySlug slug
    .then (place) =>
      _.defaults {@type}, place
    # .then EmbedService.embed {embed: defaultEmbed}

  search: ({query, sort}, {user}) =>
    @Model.search {query, sort}
    .then (places) =>
      _.map places, (place) =>
        _.defaults {@type}, place
    # .then (results) ->
    #   Promise.map results, EmbedService.embed {embed: defaultEmbed}

  getUniqueSlug: (baseSlug, suffix, attempts = 0) =>
    slug = if suffix \
         then "#{baseSlug}-#{suffix}"
         else baseSlug
    @Model.getBySlug slug
    .then (existingPlace) =>
      if attempts > MAX_UNIQUE_ID_ATTEMPTS
        return "#{baseSlug}-#{Date.now()}"
      if existingPlace
        @getUniqueSlug baseSlug, (suffix or 0) + 1, attempts  + 1
      else
        slug

  upsert: (options, {user, headers, connection}) =>
    {id, name, location, slug} = options

    matches = new RegExp(COORDINATE_REGEX_STR, 'g').exec location
    unless matches?[0] and matches?[1]
      console.log 'invalid', location
      router.throw {info: 'invalid location', status: 400}
    location = [parseFloat(matches[1]), parseFloat(matches[2])]

    Promise.all [
      (if slug
        Promise.resolve slug
      else
        slug = _.kebabCase(name)
        @getUniqueSlug slug)

      GeocoderService.reverse location
    ]
    .then ([slug, address]) =>
      address =
        locality: address?[0]?.city
        administrativeArea: address?[0]?.state
      @Model.upsert {slug, name, location, address}
