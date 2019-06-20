request = require 'request-promise'
Promise = require 'bluebird'

config = require '../config'

class FeatureLookupService
  getFeaturesByLocation: ({lat, lon}) ->
    Promise.resolve request "#{config.FEATURE_LOOKUP_HOST}/lookup",
      json: true
      qs:
        loc: "#{lat},#{lon}"


module.exports = new FeatureLookupService()
