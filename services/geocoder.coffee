NodeGeocoder = require 'node-geocoder'

config = require '../config'

# TODO: replace here with own service using pelias
class GeocoderService
  constructor: ->
    options = {
      provider: 'here'
      appId: config.HERE.APP_ID
      appCode: config.HERE.APP_CODE
    }

    @geocoder = NodeGeocoder options

  reverse: ({lat, lon}) =>
    @geocoder.reverse {lat, lon}


module.exports = new GeocoderService()
