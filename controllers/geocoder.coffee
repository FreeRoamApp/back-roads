Promise = require 'bluebird'
_ = require 'lodash'

GeocoderService = require '../services/geocoder'
PlacesService = require '../services/places'
config = require '../config'

class GeocoderCtrl
  autocomplete: ({query}, {user}) ->
    GeocoderService.autocomplete {query}

  getBoundingFromRegion: ({country, state, city}, {user}) ->
    query = "#{city.replace('+', ' ')}, #{state}"
    GeocoderService.autocomplete {query}
    .then (results) ->
      PlacesService.getBestBounding {
        location: results[0].location
      }

  getBoundingFromLocation: ({location}, {user}) ->
    PlacesService.getBestBounding {location}


module.exports = new GeocoderCtrl()
