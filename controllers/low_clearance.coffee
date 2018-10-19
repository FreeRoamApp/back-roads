Promise = require 'bluebird'
_ = require 'lodash'

LowClearance = require '../models/low_clearance'
PlaceBaseCtrl = require './place_base'

class LowClearanceCtrl extends PlaceBaseCtrl
  type: 'lowClearance'
  Model: LowClearance

module.exports = new LowClearanceCtrl()
