request = require 'request-promise'
NodeGeocoder = require 'node-geocoder'
_ = require 'lodash'

config = require '../config'

# TODO: replace HERE with pelias
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

  autocomplete: ({query}) ->
    request "#{config.PELIAS_API_URL}/autocomplete",
      json: true
      qs:
        layers: 'venue,coarse'
        text: query
        'boundary.rect.min_lat': 18.91619
        'boundary.rect.max_lat': 83.23324
        'boundary.rect.min_lon': -171.791110603
        'boundary.rect.max_lon': -52.6480987209
    .then (response) ->
      locations = _.map response.features, (location) ->
        {
          bbox: location.bbox
          location:
            lat: location.geometry.coordinates[1]
            lon: location.geometry.coordinates[0]
          text: location.properties.name
          locality: location.properties.locality
          administrativeArea: location.properties.region_a
        }


module.exports = new GeocoderService()
