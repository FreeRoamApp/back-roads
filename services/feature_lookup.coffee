request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'

config = require '../config'

class FeatureLookupService
  getFeaturesByLocation: ({lat, lon, pick, file}) ->
    Promise.resolve request "#{config.FEATURE_LOOKUP_HOST}/lookup",
      json: true
      qs:
        loc: "#{lat},#{lon}"
        pick: pick
        file: file

  getOfficeSlugByLocation: ({lat, lon}) =>
    Promise.all [
      @getFeaturesByLocation {lat, lon, file: 'blm_pad_fee'}
      @getFeaturesByLocation {lat, lon, file: 'usfs_ranger_districts'}
    ]
    .then ([blm, usfs]) ->
      if blm?[0]
        officeSlug = _.kebabCase blm[0].Loc_Nm
      else if usfs?[0]
        officeSlug = _.kebabCase usfs[0].DISTRICTNA
      else
        officeSlug = null
      officeSlug


  resetCacheByFile: (file) ->
    Promise.resolve request "#{config.FEATURE_LOOKUP_HOST}/resetCacheByFile",
      json: true
      qs:
        file: file

module.exports = new FeatureLookupService()
