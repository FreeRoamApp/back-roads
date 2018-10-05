Promise = require 'bluebird'
_ = require 'lodash'

Amenity = require '../models/amenity'
PlaceBaseCtrl = require './place_base'
GeocoderService = require '../services/geocoder'
config = require '../config'

class AmenityCtrl extends PlaceBaseCtrl
  type: 'amenity'
  Model: Amenity

  upsert: (options, {user, headers, connection}) =>
    {id, name, location, slug, amenities} = options

    matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec location
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

      @Model.upsert {slug, name, location, address, amenities}

module.exports = new AmenityCtrl()
