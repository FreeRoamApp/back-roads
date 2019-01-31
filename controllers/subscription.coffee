_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

Conversation = require '../models/conversation'
GroupUser = require '../models/group_user'
Subscription = require '../models/subscription'
PushNotificationService = require '../services/push_notification'
config = require '../config'

class SubscriptionCtrl
  getAllByGroupId: ({groupId}, {user}) ->
    Subscription.getAllByUserIdAndGroupId user.id, groupId

  # TODO: call this from client-side somewhere, max once per day or week
  # run occasionally to sync converted users to new channels
  sync: ({groupId}, {user}) =>
    Promise.all [
      Subscription.getAllByUserIdAndGroupId user.id, groupId
      @_getAllPublicChannelsByGroupId groupId
    ]
    .then ([subscriptions, publicChannels]) ->
      # groupSubscription = _.find subscriptions, ({sourceType, isEnabled}) ->
      #   sourceType.indexOf('group') is 0 and isEnabled
      channelSubscription = _.find subscriptions, ({sourceType, isEnabled}) ->
        sourceType.indexOf('channel') is 0 and isEnabled
      isConverted = channelSubscription #and not groupSubscription

      if isConverted
        publicChannelIds = _.map publicChannels, 'id'
        subscribedChannelIds = _.uniq _.map subscriptions, 'sourceId'
        newChannelIds = _.difference publicChannelIds, subscribedChannelIds
        Promise.map newChannelIds, (channelId) ->
          Promise.all [
            Subscription.subscribe {
              groupId, userId: user.id, sourceType: 'channelMessage'
              sourceId: channelId
            }
            Subscription.subscribe {
              groupId, userId: user.id, sourceType: 'channelMention'
              sourceId: channelId
            }
          ]


  subscribe: ({groupId, sourceType, sourceId, isTopic}, {user}) ->
    # TODO: if user is 'converted' to channel-based, don't allow group-based to be turned back on
    # otherwise there will be 2x notifications....
    Subscription.subscribe {
      groupId, sourceType, sourceId, isTopic
      userId: user.id
    }

  unsubscribe: ({groupId, sourceType, sourceId}, {user}) =>
    Subscription.unsubscribe {
      groupId, sourceType, sourceId
      userId: user.id
    }
    .then =>
      if sourceType.indexOf('channel') is 0
        # convert a group subscription (all channels) to channel-based)
        Subscription.getAllByUserIdAndGroupId user.id, groupId
        .then (subscriptions) =>
          groupSourceType = sourceType.replace('channel', 'group')
          groupSubscription = _.find subscriptions, (subscription) ->
            subscription.isEnabled and subscription.sourceType is groupSourceType
          if groupSubscription
            @_convertGroupSubscriptionToChannels {
              groupSubscription, newSourceType: sourceType, channelId: sourceId
            }

  _getAllPublicChannelsByGroupId: (groupId) ->
    Conversation.getAllByGroupId groupId
    .then (conversations) ->
      publicChannels = _.filter conversations, (conversation) ->
        GroupUser.hasPermission {
          meGroupUser: {
            roles: [{
              name: 'everyone'
              globalPermissions: {}
            }]
          }
          permissions: [GroupUser.PERMISSIONS.READ_MESSAGE]
          channelId: conversation.id
        }

  _convertGroupSubscriptionToChannels: (options) ->
    {groupSubscription, newSourceType, channelId} = options
    console.log 'converting...'
    # get all public channels for group
    @_getAllPublicChannelsByGroupId(groupSubscription.groupId)
    .map (channel) ->
      if "#{channel.id}" isnt "#{channelId}"
        # TODO: could optimize this more since .subscribe has more db calls
        Subscription.subscribe _.defaults {
          sourceType: newSourceType
          sourceId: channel.id
        }, _.omit(groupSubscription, ['tokens'])
    .then ->
      Subscription.unsubscribe groupSubscription

module.exports = new SubscriptionCtrl()
