Promise = require 'bluebird'
_ = require 'lodash'

Amenity = require '../models/campground'
PlaceBaseCtrl = require './place_base'

class AmenityCtrl extends PlaceBaseCtrl
  Model: Amenity

module.exports = new AmenityCtrl()
