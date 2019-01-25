AmenityAttachment = require '../models/amenity_attachment'
Base = require './place_base'

class AmenityEmbed extends Base
  AttachmentModel: AmenityAttachment

module.exports = new AmenityEmbed()
