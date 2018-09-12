Promise = require 'bluebird'
_ = require 'lodash'

Campground = require '../models/campground'
PlaceBaseCtrl = require './place_base'

class CampgroundCtrl extends PlaceBaseCtrl
  type: 'campground'
  Model: Campground

module.exports = new CampgroundCtrl()
