Promise = require 'bluebird'
_ = require 'lodash'

Office = require '../models/office'


class OfficeCtrl
  getAllByAgencySlugAndRegionSlug: ({agencySlug, regionSlug}, {user}) ->
    Office.getAllByAgencySlugAndRegionSlug agencySlug, regionSlug


module.exports = new OfficeCtrl()
