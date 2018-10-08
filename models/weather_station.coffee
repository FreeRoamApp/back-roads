_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

class WeatherStation extends PlaceBase
  SCYLLA_TABLES: []
  ELASTICSEARCH_INDICES: [
    {
      name: 'weather_stations'
      mappings:
        # common between all places
        location: {type: 'geo_point'}
        # end common
        weather: {type: 'text'}
    }
  ]

  getClosestToLocation: (location) =>
    @search {
      size: 1
      query:
        bool:
          filter: [
            {
              geo_bounding_box:
                location:
                  top_left:
                    lat: location.lat + 5
                    lon: location.lon - 5 # TODO: probably less than 5
                  bottom_right:
                    lat: location.lat - 5
                    lon: location.lon + 5
            }
          ]
      sort: [
        _geo_distance:
          location:
            lat: location.lat
            lon: location.lon
          order: 'asc'
          unit: 'km'
          distance_type: 'plane'
      ]
    }
    .then (results) ->
      results[0]

  defaultESInput: (weatherStation) ->
    weatherStation = super weatherStation
    weatherStation = _.defaults {
      weather: JSON.stringify weatherStation.weather
    } , weatherStation
    _.pick weatherStation, ['id', 'location', 'weather']

  defaultESOutput: (weatherStation) ->
    weatherStation = _.defaults {
      weather: try
        JSON.parse weatherStation.weather
      catch err
        {}
    }, weatherStation
    _.pick weatherStation, ['id', 'location', 'weather']

module.exports = new WeatherStation()
