NodeGeocoder = require 'node-geocoder'

config = require '../config'

# TODO: replace opencage with own service using pelias
class GeocoderService
  constructor: ->
    options = {
      # provider: 'opencage'
      # apiKey: '522235d337f944c0901adb9b87777bd1'
      provider: 'here'
      appId: config.HERE.APP_ID
      appCode: config.HERE.APP_CODE
    }

    @geocoder = NodeGeocoder options

  reverse: ([lat, lon]) =>
    @geocoder.reverse {lat, lon}


module.exports = new GeocoderService()
