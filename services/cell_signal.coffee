request = require 'request-promise'
Promise = require 'bluebird'

config = require '../config'

class CellSignalService
  getEstimatesByLocation: ({lat, lon}) ->
    console.log 'req cell'
    Promise.resolve request "#{config.CELL_SIGNAL_ESTIMATE_HOST}/cellCoverage",
      json: true
      qs:
        loc: "#{lat},#{lon}"


module.exports = new CellSignalService()
