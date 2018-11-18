Promise = require 'bluebird'
_ = require 'lodash'

GeocoderService = require '../services/geocoder'
config = require '../config'

class GeocoderCtrl
  autocomplete: ({query}, {user}) ->
    GeocoderService.autocomplete {query}


module.exports = new GeocoderCtrl()
