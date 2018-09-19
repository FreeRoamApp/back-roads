Promise = require 'bluebird'
_ = require 'lodash'

CellTower = require '../models/cell_tower'
PlaceBaseCtrl = require './place_base'

class CellTowerCtrl extends PlaceBaseCtrl
  type: 'cellTower'
  Model: CellTower

module.exports = new CellTowerCtrl()
