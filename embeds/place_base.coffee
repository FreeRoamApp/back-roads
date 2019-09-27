_ = require 'lodash'

class PlaceBaseEmbed
  attachmentsPreview: (place) =>
    unless place.id
      console.log 'place embed missing id'
      return null
    @AttachmentModel.getAllByParentId place.id
    .then (attachments) ->
      # there are some images where type is empty instead of 'image'
      attachments = _.filter attachments, ({type}) -> type isnt 'video'
      {
        first: _.first attachments
        count: attachments?.length or 0
      }

module.exports = PlaceBaseEmbed
