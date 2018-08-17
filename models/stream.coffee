Promise = require 'bluebird'
_ = require 'lodash'

StreamService = require '../services/stream'

class Stream
  streamCreate: (obj) =>
    channels = _.map @streamChannelsBy, (channelBy) =>
      channelByUuid = obj[channelBy]
      "#{@streamChannelKey}:#{channelBy}:#{channelByUuid}"
    StreamService.create obj, channels

  streamUpdateByUuid: (id, obj) =>
    channels = _.map @streamChannelsBy, (channelBy) =>
      channelByUuid = obj?[channelBy]
      "#{@streamChannelKey}:#{channelBy}:#{channelByUuid}"
    StreamService.updateByUuid id, obj, channels

  streamDeleteByUuid: (id, obj) =>
    channels = _.map @streamChannelsBy, (channelBy) =>
      channelByUuid = obj?[channelBy]
      "#{@streamChannelKey}:#{channelBy}:#{channelByUuid}"
    StreamService.deleteByUuid id, channels

  stream: (options) =>
    {emit, socket, route, channelBy, channelByUuid,
      initial, initialPostFn, postFn} = options
    StreamService.stream {
      channel: "#{@streamChannelKey}:#{channelBy}:#{channelByUuid}"
      emit
      socket
      route
      initial: initial.map (initialPostFn or _.identity)
      postFn
    }

  unsubscribe: ({socket, channelBy, channelByUuid}) =>
    StreamService.unsubscribe {
      channel: "#{@streamChannelKey}:#{channelBy}:#{channelByUuid}"
      socket
    }

module.exports = Stream
