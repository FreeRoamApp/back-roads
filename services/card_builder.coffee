request = require 'request-promise'
Promise = require 'bluebird'
config = require '../config'

class CardBuilderService
  createTripCard: ({url}) ->
    tripId = url.match(/trip\/([a-zA-Z0-9-]*)/)[1]
    Promise.resolve {card: {type: 'trip', sourceId: tripId}}

  create: ({url, callbackUrl}) =>
    Promise.resolve request "#{config.DEALER_API_URL}/cards", {
      method: 'POST'
      body: {url, callbackUrl}
      json: true
    }

module.exports = new CardBuilderService()
