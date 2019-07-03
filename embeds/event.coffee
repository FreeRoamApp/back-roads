CampgroundAttachment = require '../models/campground_attachment'
Base = require './place_base'

class EventEmbed extends Base
  AttachmentModel: CampgroundAttachment # FIXME

module.exports = new EventEmbed()
