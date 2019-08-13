Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'

Agency = require '../models/agency'
Office = require '../models/office'
FeatureLookupService = require '../services/feature_lookup'
config = require '../config'

class AgencyCtrl
  getAll: ({}, {user}) ->
    Agency.getAll()

  getAgencyInfoFromLocation: ({location}, {user}) ->
    console.log 'get', location
    # TODO: used in place_base upsert, make fn out of this
    matches = new RegExp(config.COORDINATE_REGEX_STR, 'g').exec location
    unless matches?[0] and matches?[1]
      console.log 'invalid', location
      router.throw {
        status: 400
        info:
          langKey: 'error.invalidCoordinates'
          step: 'initialInfo'
          field: 'location'
      }
    location = {
      lat: parseFloat(matches[1])
      lon: parseFloat(matches[2])
    }
    FeatureLookupService.getOfficeSlugByLocation location
    .then (officeSlug) ->
      if officeSlug
        Office.getBySlug officeSlug


module.exports = new AgencyCtrl()
