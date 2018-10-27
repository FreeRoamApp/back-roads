_ = require 'lodash'

class PlaceBaseEmbed
  attachmentsPreview: (place) =>
    @AttachmentModel.getAllByParentId place.id
    .then (attachments) ->
      {
        first: _.first attachments
        count: attachments?.length or 0
      }

module.exports = PlaceBaseEmbed
