Promise = require 'bluebird'
_ = require 'lodash'

Overnight = require '../models/overnight'
PlaceBaseCtrl = require './place_base'

class OvernightCtrl extends PlaceBaseCtrl
  type: 'overnight'
  Model: Overnight

module.exports = new OvernightCtrl()
