Promise = require 'bluebird'
_ = require 'lodash'

Region = require '../models/region'


class RegionCtrl
  getAllByAgencySlug: ({agencySlug}, {user}) ->
    Region.getAllByAgencySlug agencySlug


module.exports = new RegionCtrl()
