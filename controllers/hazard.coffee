Promise = require 'bluebird'
_ = require 'lodash'

Hazard = require '../models/hazard'
PlaceBaseCtrl = require './place_base'

class HazardCtrl extends PlaceBaseCtrl
  type: 'lowClearance'
  Model: Hazard

module.exports = new HazardCtrl()
