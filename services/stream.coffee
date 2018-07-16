Promise = require 'bluebird'
_ = require 'lodash'

PubSubService = require './pub_sub'

class StreamService
  constructor: ->
    @openSubscriptions = {}
    setInterval =>
      subscriptionsOpen = _.reduce @openSubscriptions, (count, socket) ->
        count += _.keys(socket).length
        count
      , 0
      if subscriptionsOpen > 10
        console.log 'subscriptions open: ', subscriptionsOpen
    , 100000

  exoidDisconnect: (socket) =>
    _.map @openSubscriptions[socket.id], (subscription) ->
      subscription.unsubscribe()
    delete @openSubscriptions[socket.id]

  create: (obj, channels) ->
    PubSubService.publish channels, {action: 'create', obj}

  updateById: (id, obj, channels) ->
    PubSubService.publish channels, {id, action: 'update', obj}

  deleteById: (id, channels) ->
    PubSubService.publish channels, {id, action: 'delete'}

  # postFn called when received (many times)
  # best to put in the create method if possible
  stream: ({emit, socket, route, channel, initial, postFn}) =>
    initial
    .map postFn or _.identity
    .tap =>
      subscription = PubSubService.subscribe channel, ({id, action, obj}) ->
        isInsert = true
        Promise.resolve obj
        .then postFn or _.identity
        .then (newItem) ->
          emit {
            initial: null
            changes: [{
              oldId: if action is 'create' then null else id
              newVal: if action is 'delete' then null else newItem
            }]
          }

      subscriptionKey = channel

      if @openSubscriptions[socket.id]?[subscriptionKey]
        @openSubscriptions[socket.id][subscriptionKey].unsubscribe()

      @openSubscriptions[socket.id] ?= {}
      @openSubscriptions[socket.id][subscriptionKey] = subscription

  unsubscribe: ({socket, channel}) =>
    subscriptionKey = channel
    if @openSubscriptions[socket.id]?[subscriptionKey]
      @openSubscriptions[socket.id][subscriptionKey].unsubscribe()

module.exports = new StreamService()
