CampgroundAttachment = require '../models/campground_attachment'
Base = require './place_base'

class CampgroundEmbed extends Base
  AttachmentModel: CampgroundAttachment

module.exports = new CampgroundEmbed()
