request = require 'request-promise'
Promise = require 'bluebird'

config = require '../config'

class FeatureLookupService
  getFeaturesByLocation: ({lat, lon, pick, file}) ->
    Promise.resolve request "#{config.FEATURE_LOOKUP_HOST}/lookup",
      json: true
      qs:
        loc: "#{lat},#{lon}"
        pick: pick
        file: file

  resetCacheByFile: (file) ->
    Promise.resolve request "#{config.FEATURE_LOOKUP_HOST}/resetCacheByFile",
      json: true
      qs:
        file: file

module.exports = new FeatureLookupService()
