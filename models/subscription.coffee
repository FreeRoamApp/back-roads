_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'
request = require 'request-promise'

Base = require './base'
Group = require './group'
PushToken = require './push_token'
cknex = require '../services/cknex'
config = require '../config'

# topics are NOT secure. anyone can subscribe. for secure messaging, always
# use device tokens. for private channels, device tokens

TYPES =
  GROUP_MENTION: 'groupMention'
  GROUP_MESSAGE: 'groupMessage'
  GROUP_ROLE: 'groupRole'
  CHANNEL_MENTION: 'channelMention'
  CHANNEL_MESSAGE: 'channelMessage'

  # global:
  PRIVATE_MESSAGE: 'privateMessage'
  # maybe eventually people can narrow this down in the same way group <-> channels work
  # unsubscribing to one removes social 'all' and is more granular
  SOCIAL: 'social'
  NEWS: 'news'

scyllaFields =
  userId: 'uuid'
  groupId: {type: 'uuid', defaultFn: -> config.EMPTY_UUID}
  sourceType: {type: 'text', defaultFn: -> 'all'}
  sourceId: {type: 'text', defaultFn: -> 'all'} # id or 'all'
  isTopic: {type: 'boolean', defaultFn: -> false} # whether or not this corresponds to fcm topic
  isEnabled: {type: 'boolean', defaultFn: -> true}
  tokens: {type: 'map', subType: 'text', subType2: 'text'} # token: deviceId
  lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}

class Subscription extends Base
  TYPES: TYPES

  getScyllaTables: ->
    [
      {
        name: 'subscriptions_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: [
            'groupId', 'sourceType', 'sourceId'
          ]
      }
      # will be used to blast to private groups where a pushTopic isn't secure
      {
        name: 'subscriptions_by_topic'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['groupId', 'sourceType', 'sourceId']
          clusteringColumns: [
            'userId'
          ]
      }
      # used to unsubscribe a device when logging in as a different user
      {
        name: 'subscriptions_by_token'
        keyspace: 'free_roam'
        fields:
          userId: 'uuid'
          groupId: {type: 'uuid', defaultFn: -> config.EMPTY_UUID}
          sourceType: {type: 'text', defaultFn: -> 'all'}
          sourceId: {type: 'text', defaultFn: -> 'all'} # id or 'all'
          token: {type: 'text', defaultFn: -> 'none'}
        ignoreUpsert: true
        primaryKey:
          partitionKey: ['token']
          clusteringColumns: [
            'groupId', 'sourceType', 'sourceId'
          ]
      }
    ]

  getAllByUserId: (userId) =>
    cknex().select '*'
    .from 'subscriptions_by_userId'
    .where 'userId', '=', userId
    .run()
    .map @defaultOutput

  getAllByUserIdAndGroupId: (userId, groupId) =>
    cknex().select '*'
    .from 'subscriptions_by_userId'
    .where 'userId', '=', userId
    .andWhere 'groupId', '=', groupId
    .run()
    .map @defaultOutput

  getAllByToken: (token) =>
    cknex().select '*'
    .from 'subscriptions_by_token'
    .where 'token', '=', token
    .run()
    .map @defaultOutput

  removeTokenByUserId: (userId, token) =>
    @getAllByUserId userId
    .map (subscription) =>
      @upsertByRow subscription, {}, {
        remove:
          tokens: [token]
      }

  removeTokenBySubscriptionToken: (subscriptionToken) =>
    subscription = _.omit subscriptionToken, 'token'
    @upsertByRow subscription, {}, {
      remove:
        tokens: [subscriptionToken.token]
    }

  subscribeNewTokenByUserId: (userId, {token, deviceId}) =>
    @getAllByUserId userId
    .map (subscription) =>
      (if subscription.isTopic and subscription.isEnabled
        @fcmSubscribeToTopicByToken token, @getTopicFromSubscription subscription
      else
        Promise.resolve null
      ).then =>
        Promise.all [
          @upsertByRow subscription, {}, {
            add: {
              tokens:
                "#{token}": deviceId
            }
          }

          # other two tables are 'added' to above
          @upsertByToken _.defaults {token}, subscription
        ]

  subscribeInitial: (user) =>
    Promise.all [
      @subscribe {
        userId: user.id
        token: 'none'
        deviceId: 'none'
        sourceType: @TYPES.PRIVATE_MESSAGE
      }
      @subscribe {
        userId: user.id
        token: 'none'
        deviceId: 'none'
        sourceType: @TYPES.SOCIAL
      }
      @subscribe {
        userId: user.id
        token: 'none'
        deviceId: 'none'
        sourceType: @TYPES.NEWS
        isTopic: true
      }
    ]

  # go through all pushTokens a user has and subscribe them to the topic.
  # max 1 subscription per device,
  subscribe: (subscription) =>
    {userId, groupId, sourceType, sourceId} = subscription
    topic = @getTopicFromSubscription subscription

    PushToken.getAllByUserId userId
    .then (pushTokens) =>
      # still store push subscriptions if a token isn't set, that way when one does get
      # set, the user will subscribe to correct subscriptions
      if _.isEmpty pushTokens
        pushTokens = [{userId, deviceId: 'none', token: 'none'}]

      Promise.all _.filter [
        @upsert subscription, {
          add:
            tokens: _.reduce pushTokens, (obj, pushToken) ->
              obj[pushToken.token] = pushToken.deviceId
              obj
            , {}
        }
        Promise.map pushTokens, ({token}) =>
          unless token is 'none'
            Promise.all _.filter [
              if subscription.isTopic
                @fcmSubscribeToTopicByToken token, topic
              # other two tables are 'added' to above
              @upsertByToken _.defaults {token}, subscription
            ]
      ]

  upsertByToken: (subscription) =>
    subscription = @defaultInput subscription

    cknex().update 'subscriptions_by_token'
    .set _.pick subscription, [
      'userId'
    ]
    .where 'token', '=', subscription.token
    .andWhere 'groupId', '=', subscription.groupId
    .andWhere 'sourceType', '=', subscription.sourceType
    .andWhere 'sourceId', '=', subscription.sourceId
    .run()

  unsubscribeToGroupByUserId: (userId, groupId) =>
    @getAllByUserIdAndGroupId userId, groupId
    .map (subscription) =>
      @unsubscribeBySubscription subscription, {shouldDelete: true}

  unsubscribe: (subscription) =>
    @getByRow subscription
    .then @unsubscribeBySubscription

  unsubscribeBySubscription: (subscription, {shouldDelete} = {}) =>
    topic = @getTopicFromSubscription subscription

    Promise.all _.filter [
      if shouldDelete
        @deleteByRow subscription
      else
        @upsertByRow subscription, {isEnabled: false}
      if subscription?.isTopic
        Promise.all _.map subscription.tokens, (deviceId, token) =>
          @fcmUnsubscribeToTopicByToken token, topic
    ]

  # row from subscriptions_by_token
  unsubscribeBySubscriptionToken: (subscriptionToken) =>
    topic = @getTopicFromSubscription subscriptionToken

    Promise.all _.filter [
      @removeTokenBySubscriptionToken subscriptionToken
      @fcmUnsubscribeToTopicByToken subscriptionToken.token, topic
    ]

  subscribeToGroup: ({userId, groupId}) =>
    Group.getById groupId
    .then (group) =>
      defaultNotifications = group.data?.defaultNotifications or [
        @TYPES.GROUP_MESSAGE
        @TYPES.GROUP_MENTION
      ]
      Promise.all _.map(defaultNotifications, (sourceType) =>
        @subscribe {
          userId
          groupId
          sourceType: sourceType
          sourceId: 'all'
          isTopic: sourceType isnt @TYPES.GROUP_MENTION
        }).concat [
          # @everyone mentions in group
          @subscribe {
            userId
            groupId
            sourceType: @TYPES.GROUP_ROLE
            sourceId: 'everyone'
            isTopic: true
          }
      ]
    # 'everyone'

  fcmSubscribeToTopicByToken: (token, topic) =>
    if token is 'none'
      return Promise.resolve null

    # if (config.ENV isnt config.ENVS.PROD or config.IS_STAGING)
    #   return Promise.resolve null

    base = 'https://iid.googleapis.com/iid/v1'
    console.log 'req topic'
    request "#{base}/#{token}/rel/topics/#{topic}", {
      json: true
      method: 'POST'
      headers:
        'Authorization': "key=#{config.GOOGLE_API_KEY}"
      body: {}
    }
    .catch (err) ->
      # console.log err
      console.log 'sub topic err', "#{base}/#{token}/rel/topics/#{topic}"

  fcmUnsubscribeToTopicByToken: (token, topic) =>
    if token is 'none'
      return Promise.resolve null

    base = 'https://iid.googleapis.com/iid/v1'
    console.log 'req unsub'
    request "#{base}/#{token}/rel/topics/#{topic}", {
      json: true
      method: 'DELETE'
      headers:
        'Authorization': "key=#{config.GOOGLE_API_KEY}"
      body: {}
    }
    .catch (err) ->
      console.log 'unsub topic err', "#{base}/token/rel/topics/#{topic}"

  getTopicFromSubscription: ({groupId, sourceType, sourceId}) ->
    sourceType ?= 'all'
    sourceId ?= 'all'
    # : not a valid topic character
    "#{groupId}~#{sourceType}~#{sourceId}"


module.exports = new Subscription()
