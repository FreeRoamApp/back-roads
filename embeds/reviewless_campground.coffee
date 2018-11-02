ReviewlessCampgroundAttachment = require '../models/reviewless_campground_attachment'
Base = require './place_base'

class ReviewlessCampgroundEmbed extends Base
  AttachmentModel: ReviewlessCampgroundAttachment

module.exports = new ReviewlessCampgroundEmbed()
