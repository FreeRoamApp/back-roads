amazon = require 'amazon-product-api'

config = require '../config'

class AmazonService
  constructor: ->
    console.log 'TODO AWS'
    # console.log 'aws', config.AWS.ACCESS_KEY_ID
    # @client = amazon.createClient {
    #   awsId: config.AWS.ACCESS_KEY_ID
    #   awsSecret: config.AWS.SECRET_ACCESS_KEY
    #   awsTag: ''
    # }
    # @client.itemSearch(
    #   director: 'Quentin Tarantino'
    #   actor: 'Samuel L. Jackson'
    #   searchIndex: 'DVD'
    #   audienceRating: 'R'
    #   responseGroup: 'ItemAttributes,Offers,Images').then((results) ->
    #   console.log JSON.stringify results
    #   return
    # ).catch (err) ->
    #   console.log 'err'
    #   console.log JSON.stringify err
    #   return

module.exports = new AmazonService()
