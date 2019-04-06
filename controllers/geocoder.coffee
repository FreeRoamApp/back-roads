Promise = require 'bluebird'
_ = require 'lodash'

GeocoderService = require '../services/geocoder'
PlacesService = require '../services/places'
config = require '../config'

class GeocoderCtrl
  autocomplete: ({query}, {user}) ->
    GeocoderService.autocomplete {query}

  getBoundingFromRegion: ({country, state, city}, {user}) ->
    # TODO: get closest 10 locations and have map show all
    query = "#{city.replace('+', ' ')}, #{state}"
    console.log query
    GeocoderService.autocomplete {query}
    .then (results) ->
      console.log results
      PlacesService.getBestBounding {
        location: results[0].location
      }
    .then (bounding) ->
      console.log bounding
      bounding


module.exports = new GeocoderCtrl()
