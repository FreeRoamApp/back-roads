request = require 'request-promise'
NodeGeocoder = require 'node-geocoder'
_ = require 'lodash'

Campground = require '../models/campground'
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
    matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec query
    coordinates = if matches
      {
        lat: parseFloat(matches[1])
        lon: parseFloat(matches[2])
      }

    Promise.all [
      if coordinates
        @reverse coordinates

      Campground.search {
        query:
          match_phrase_prefix:
            name: query
        limit: 3
      }

      request "#{config.PELIAS_API_URL}/autocomplete",
        json: true
        qs:
          layers: 'venue,coarse'
          text: query
          'boundary.rect.min_lat': 18.91619
          'boundary.rect.max_lat': 83.23324
          'boundary.rect.min_lon': -171.791110603
          'boundary.rect.max_lon': -52.6480987209
    ]
    .then ([coordinateLocation, campgrounds, response]) ->
      # TODO: prepend coordinates if query matches coordinates
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
      if coordinates
        locations.unshift {
          bbox: null
          location: coordinates
          text: "#{coordinates.lat}, #{coordinates.lon}"
          locality: coordinateLocation?.locality
          administrativeArea: coordinateLocation?.administrativeArea
        }
      if campgrounds?.total
        locations = campgrounds.places.concat locations

      locations


module.exports = new GeocoderService()
