request = require 'request-promise'
NodeGeocoder = require 'node-geocoder'
_ = require 'lodash'

config = require '../config'

class GeocoderService
  reverse: ({lat, lon}) ->
    request "#{config.PELIAS_API_URL}/reverse",
      json: true
      qs:
        'point.lat': lat
        'point.lon': lon
    .then (response) ->
      data = response.features?[0]?.properties
      {
        locality: data?.locality or data?.name
        administrativeArea: data?.region_a
      }

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
