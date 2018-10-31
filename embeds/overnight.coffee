OvernightAttachment = require '../models/overnight_attachment'
Base = require './place_base'

class OvernightEmbed extends Base
  AttachmentModel: OvernightAttachment

module.exports = new OvernightEmbed()
