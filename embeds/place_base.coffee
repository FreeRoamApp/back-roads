_ = require 'lodash'

class PlaceBaseEmbed
  attachmentsPreview: (place) =>
    unless place.id
      console.log 'place embed missing id'
      return null
    @AttachmentModel.getAllByParentId place.id
    .then (attachments) ->
      {
        first: _.first attachments
        count: attachments?.length or 0
      }

module.exports = PlaceBaseEmbed
