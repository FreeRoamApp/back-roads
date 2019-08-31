Promise = require 'bluebird'
_ = require 'lodash'

GeocoderService = require '../services/geocoder'
RoutingService = require '../services/routing'
FeatureLookupService = require '../services/feature_lookup'
PlacesService = require '../services/places'
statesAbbr = require '../resources/data/states_abbr'
config = require '../config'

class GeocoderCtrl
  autocomplete: ({query}, {user}) ->
    GeocoderService.autocomplete {query}

  getBoundingFromRegion: ({country, state, city}, {user}) ->
    if city is 'all'
      query = statesAbbr[state.toUpperCase()] or state
    else
      query = "#{city.replace('+', ' ')}, #{state}"
    GeocoderService.autocomplete {query}
    .then (results) ->
      PlacesService.getBestBounding {
        bbox: results[0].bbox
        location: results[0].location
      }

  getBoundingFromLocation: ({location}, {user}) ->
    PlacesService.getBestBounding {location}

  getFeaturesFromLocation: ({location, file}, {user}) ->
    FeatureLookupService.getFeaturesByLocation _.defaults {file}, location


module.exports = new GeocoderCtrl()
