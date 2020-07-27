request = require 'request-promise'
NodeGeocoder = require 'node-geocoder'
_ = require 'lodash'

Autocomplete = require '../models/autocomplete'
Campground = require '../models/campground'
config = require '../config'

class GeocoderService
  reverse: ({lat, lon}) ->
    request "https://api.mapbox.com/geocoding/v5/mapbox.places/#{lon},#{lat}.json",
      json: true
      qs:
        access_token: config.MAPBOX_ACCESS_TOKEN
    .then (response) ->
      data = response.features?[0]?.properties
      {
        locality: _.find(response.features, ({place_type}) ->
          place_type?[0] is 'locality'
        )?.text
        administrativeArea: _.find(response.features, ({place_type}) ->
          place_type?[0] is 'region'
        )?.text
      }
    .catch (err) ->
      console.log 'reverse err', err
      {}

  autocomplete: ({query, includeGeocode}) ->
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
      }, {
        outputFn: (campground) ->
          _.defaults {type: 'campground'}, _.pick campground, [
            'id', 'name', 'location', 'slug'
          ]
      }

      Autocomplete.search {
        query: 
          prefix:
            # TODO: text field should be type text, not keyword
            text: _.startCase(query.toLowerCase())
      }

      # request "#{config.PELIAS_API_URL}/autocomplete",
      # if includeGeocode and query
      #   request("https://api.mapbox.com/geocoding/v5/mapbox.places/#{query}.json",
      #     json: true
      #     qs:
      #       access_token: config.MAPBOX_ACCESS_TOKEN
      #       autocomplete: true
      #       bbox: '-171.791110603,18.91619,-52.6480987209,83.23324'
      #       # layers: 'venue,coarse'
      #       # text: query
      #       # 'boundary.rect.min_lat': 18.91619
      #       # 'boundary.rect.max_lat': 83.23324
      #       # 'boundary.rect.min_lon': -171.791110603
      #       # 'boundary.rect.max_lon': -52.6480987209
      #   ).catch (err) ->
      #     console.log 'autocomplete err', err
    ]
    .then ([coordinateLocation, campgrounds, autocompletes, response]) ->
      # TODO: prepend coordinates if query matches coordinates
      locations = _.map response?.features, (location) ->
        {
          bbox: location.bbox
          location:
            lat: location.geometry.coordinates[1]
            lon: location.geometry.coordinates[0]
          # text: location.properties.name
          text: location.text
          # locality: location.properties.locality
          # administrativeArea: location.properties.region_a
          locality: _.find(location.context, ({id}) ->
            id?.indexOf('place') is 0
          )?.text
          administrativeArea: _.find(location.context, ({id}) ->
            id?.indexOf('region') is 0
          )?.text
        }
      
      if autocompletes
        locations = locations.concat autocompletes

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
