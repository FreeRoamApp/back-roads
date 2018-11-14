request = require 'request-promise'

config = require '../config'

class CellSignalService
  getEstimatesByLocation: ({lat, lon}) ->
    request "#{config.CELL_SIGNAL_ESTIMATE_HOST}/cellCoverage",
      json: true
      qs:
        loc: "#{lat},#{lon}"


module.exports = new CellSignalService()
