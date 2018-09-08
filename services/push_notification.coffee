_ = require 'lodash'
apn = require 'apn'
gcm = require 'node-gcm'
Promise = require 'bluebird'
uuid = require 'node-uuid'
webpush = require 'web-push'
request = require 'request-promise'
randomSeed = require 'random-seed'

config = require '../config'
EmbedService = require './embed'
User = require '../models/user'
Notification = require '../models/notification'
PushToken = require '../models/push_token'
PushTopic = require '../models/push_topic'
Group = require '../models/group'
GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
Language = require '../models/language'
UserBlock = require '../models/user_block'

ONE_DAY_SECONDS = 3600 * 24
RETRY_COUNT = 10
CONSECUTIVE_ERRORS_UNTIL_INACTIVE = 10
MAX_INT_32 = 2147483647

TYPES =
  CONVERSATION_MESSAGE: 'conversationMessage'
  CHAT_MENTION: 'chatMention'
  PRIVATE_MESSAGE: 'privateMessage'
  GROUP: 'group'

defaultUserEmbed = [
  EmbedService.TYPES.USER.GROUP_USER_SETTINGS
]
cdnUrl = "https://#{config.CDN_HOST}/d/images/freeroam"

class PushNotificationService
  constructor: ->
    console.log 'new gcm'
    @gcmConn = new gcm.Sender(config.GOOGLE_API_KEY)

    webpush.setVapidDetails(
      config.VAPID_SUBJECT,
      config.VAPID_PUBLIC_KEY,
      config.VAPID_PRIVATE_KEY
    )

  TYPES: TYPES

  isGcmHealthy: ->
    Promise.resolve true # TODO

  sendWeb: (token, message) ->
    # doesn't seem to work with old VAPID tokens
    # tokenObj = JSON.parse token
    # request 'https://iid.googleapis.com/v1/web/iid', {
    #   json: true
    #   method: 'POST'
    #   headers:
    #     'Authorization': "key=#{config.GOOGLE_API_KEY}"
    #   body:
    #     endpoint: tokenObj.endpoint
    #     keys: tokenObj.keys
    # }
    webpush.sendNotification JSON.parse(token), JSON.stringify message

  sendFcm: (to, {title, text, type, data, icon, toType, notId}, {isiOS} = {}) =>
    toType ?= 'token'
    new Promise (resolve, reject) =>
      messageOptions = {
        priority: 'high'
        contentAvailable: true
      }
      # ios and android take different formats for whatever reason...
      # if you pass notification to android, it uses that and doesn't use data
      # https://github.com/phonegap/phonegap-plugin-push/issues/387
      if isiOS
        messageOptions.notification =
          title: title
          body: text
          # icon: 'notification_icon'
          color: config.NOTIFICATION_COLOR
        messageOptions.data = data
      else
        messageOptions.data =
          title: title
          message: text
          ledColor: [0, 255, 0, 0]
          image: if icon then icon else null
          payload: data
          data: data
          # https://github.com/phonegap/phonegap-plugin-push/issues/158
          # unfortunately causes flash as app opens and closes.
          # spent 3 hours trying to solve and no luck
          # https://github.com/phonegap/phonegap-plugin-push/issues/1846
          # 'force-start': 1
          # 'content-available': true
          priority: 1
          actions: _.filter [
            if type in [
              @TYPES.CONVERSATION_MESSAGE
              @TYPES.PRIVATE_MESSAGE
            ]
              {
                title: 'REPLY'
                callback: 'app.pushActions.reply'
                foreground: false
                inline: true
              }
          ]
          type: type
          icon: 'notification_icon'
          color: config.NOTIFICATION_COLOR
          notId: notId or (Date.now() % 100000) # should be int, not uuid.v4()
          # android_channel_id: 'test'

      notification = new gcm.Message messageOptions

      if toType is 'token'
        toObj = {registrationTokens: [to]}
      else if toType is 'topic' and to
        toObj = {topic: "/topics/#{to}"}
        # toObj = {condition: "'#{to}' in topics || '#{to}2' in topics"}

      console.log 'try gcm'
      @gcmConn.send notification, toObj, RETRY_COUNT, (err, result) ->
        console.log 'gcm', err, result
        successes = result?.success or result?.message_id
        if err or not successes
          reject err
        else
          resolve true

  sendToConversation: (conversation, options = {}) =>
    {skipMe, meUser, text, mentionUserIds, mentionRoles, conversationMessage} = options

    mentionUserIds ?= []
    (if conversation.groupId
      Group.getById "#{conversation.groupId}"
      .then (group) -> {group}
    else
      Promise.resolve {userIds: conversation.userIds}
    ).then ({group, userIds}) =>
      if group
        path = {
          key: 'groupChatConversation'
          params:
            groupId: group.key or group.id
            conversationId: conversation.id
            gameKey: config.DEFAULT_GAME_KEY
          qs:
            minId: conversationMessage?.id
        }
      else
        path = {
          key: 'conversation'
          params:
            id: conversation.id
            gameKey: config.DEFAULT_GAME_KEY
        }

      message =
        title: group?.name or User.getDisplayName meUser
        type: if group \
              then @TYPES.CONVERSATION_MESSAGE
              else @TYPES.PRIVATE_MESSAGE
        text: if group \
              then "#{User.getDisplayName(meUser)}: #{text}"
              else text
        url: "https://#{config.FREE_ROAM_HOST}"
        icon: if group \
              then "#{cdnUrl}/groups/badges/#{group.badgeId}.png"
              else meUser?.avatarImage?.versions[0].url
        data:
          conversationId: conversation.id
          contextId: conversation.id
          path: path
        notId: randomSeed.create(conversation.id)(MAX_INT_32)

      mentionMessage = _.defaults {type: @TYPES.CHAT_MENTION}, message

      Promise.all [
        @sendToRoles mentionRoles, mentionMessage, {
          fromUserId: meUser.id, groupId: conversation.groupId
          conversation: conversation
        }

        @sendToUserIds mentionUserIds, mentionMessage, {
          skipMe, fromUserId: meUser.id, groupId: conversation.groupId
          conversation: conversation
        }

        @sendToUserIds userIds, message, {
          skipMe, fromUserId: meUser.id, groupId: conversation.groupId
          conversation: conversation
        }

        # TODO: have users subscribe to conversation
        # and send to subs of conversation
        if group?.type and group.type isnt 'public' and not group.key
          @sendToGroupTopic group, message
        else
          Promise.resolve null
      ]

  # topics are NOT secure. anyone can subscribe. for secure messaging, always
  # use the deviceToken. for private channels, use deviceToken

  sendToPushTopic: (pushTopic, message, {language, forceDevSend} = {}) =>
    topic = @getTopicStrFromPushTopic pushTopic

    # legacy
    # topic = "group-#{pushTopic.groupId}"
    # topic = 'es'

    if message.titleObj
      message.title = Language.get message.titleObj.key, {
        file: 'pushNotifications'
        language: language
        replacements: message.titleObj.replacements
      }
    if message.textObj
      message.text = Language.get message.textObj.key, {
        file: 'pushNotifications'
        language: language
        replacements: message.textObj.replacements
      }

    message = {
      toType: 'topic'
      type: message.type
      title: message.title
      text: message.text
      data: message.data
    }

    if (config.ENV isnt config.ENVS.PROD or config.IS_STAGING) and
        not forceDevSend
      console.log 'send notification', pushTopic, topic, JSON.stringify message
      # return Promise.resolve()

    @sendFcm topic, message


  sendToGroupTopic: (group, message) =>
    @sendToPushTopic {groupId: group.id}, message, {language: group.language}

  sendToRoles: (roles, message, {groupId} = {}) ->
    Promise.map roles, (role) =>
      pushTopic = {groupId, sourceType: 'role', sourceId: role}
      @sendToPushTopic pushTopic, message

  sendToUserIds: (userIds, message, options = {}) ->
    {skipMe, fromUserId, groupId, conversation} = options
    Promise.each userIds, (userId) =>
      unless userId is fromUserId
        user = User.getById userId, {preferCache: true}
        if groupId
          user = user.then EmbedService.embed {
            embed: defaultUserEmbed
            options:
              groupId
          }
        user
        .then (user) =>
          @send user, message, {fromUserId, groupId, conversation}

  send: (user, message, {fromUserId, groupId, conversation} = {}) =>
    unless message and (
      message.title or message.text or message.titleObj or message.textObj
    )
      return Promise.reject new Error 'missing message'

    language = user.language or Language.getLanguageByCountry user.country

    message.data ?= {}
    if message.titleObj
      message.title = Language.get message.titleObj.key, {
        file: 'pushNotifications'
        language: language
        replacements: message.titleObj.replacements
      }
    if message.textObj
      message.text = Language.get message.textObj.key, {
        file: 'pushNotifications'
        language: language
        replacements: message.textObj.replacements
      }

    notificationData = {path: message.data.path}
    if conversation
      notificationData.conversationId = conversation.id
      if conversation.type is 'pm'
        uniqueId = "pm-#{conversation.id}"

    Notification.upsert {
      userId: user.id
      groupId: groupId or config.EMPTY_UUID
      uniqueId: uniqueId
      fromId: fromUserId
      title: message.title
      text: message.text
      data: notificationData
    }

    if user.groupUserSettings
      settings = _.defaults(
        user.groupUserSettings.globalNotifications, config.DEFAULT_NOTIFICATIONS
      )
      if not settings?[message.type]
        return Promise.resolve null

    if config.ENV is config.ENVS.DEV and not message.forceDevSend
      console.log 'send notification', user.id, message
      return Promise.resolve()

    successfullyPushedToNative = false

    @_checkIfBlocked user, fromUserId
    .then ->
      PushToken.getAllByUserId user.id
    .then (pushTokens) =>
      pushTokens = _.filter pushTokens, (pushToken) ->
        pushToken.isActive

      pushTokenDevices = _.groupBy pushTokens, 'deviceId'
      pushTokens = _.map pushTokenDevices, (tokens) ->
        return tokens[0]

      Promise.map pushTokens, (pushToken) =>
        {sourceType, token, errorCount} = pushToken
        fn = if sourceType is 'web' \
             then @sendWeb
             else if sourceType in ['android', 'ios-fcm', 'web-fcm']
             then @sendFcm

        unless fn
          console.log 'no fn', sourceType
          return

        fn token, message, {isiOS: sourceType is 'ios-fcm'}
        .then ->
          successfullyPushedToNative = true
          if errorCount
            PushToken.upsert _.defaults({
              errorCount: 0
            }, pushToken)
        .catch (err) ->
          newErrorCount = errorCount + 1
          if newErrorCount >= CONSECUTIVE_ERRORS_UNTIL_INACTIVE
            Promise.all [
              PushToken.deleteByPushToken pushToken
              PushTopic.deleteByPushToken pushToken
            ]
          else
            PushToken.upsert _.defaults({
              errorCount: newErrorCount
            }, pushToken)

          # if newErrorCount >= CONSECUTIVE_ERRORS_UNTIL_INACTIVE
          #   PushToken.getAllByUserId user.id
          #   .then (tokens) ->
          #     if _.isEmpty tokens
          #       User.updateByUser user, {
          #         hasPushToken: false
          #       }

  _checkIfBlocked: (user, fromUserId) ->
    if fromUserId
      UserBlock.getAllByUserId user.id
      .then (blockedUsers) ->
        isBlocked = _.find blockedUsers, {blockedId: fromUserId}
        if isBlocked
          throw new Error 'user blocked'
    else
      Promise.resolve()

  subscribeToAllUserTopics: ({userId, token, deviceId}) ->
    Promise.all [
      PushToken.getAllByUserId userId
      PushTopic.getAllByUserId userId
    ]
    .then ([pushTokens, pushTopics]) =>
      topics = pushTopics.concat [{
        userId: userId
        groupId: config.EMPTY_UUID
        sourceType: 'all'
        sourceId: 'all'
      }]
      uniqueTopics = _.uniqBy topics, (topic) ->
        _.omit topic, ['token']

      Promise.map uniqueTopics, (topic) =>
        @subscribeToTopicByToken token, topic
        .then ->
          PushTopic.upsert _.defaults {
            token: token
            deviceId: deviceId
          }, topic

  # go through all pushTokens a user has and subscribe them to the topic.
  # max 1 subscription per device,
  subscribeToPushTopic: (topic) =>
    {userId, groupId, sourceType, sourceId} = topic

    Promise.all [
      PushToken.getAllByUserId userId
      PushTopic.getAllByUserId userId
    ]
    .then ([pushTokens, topics]) =>
      # still store push topics if a token isn't set, that way when one does get
      # set, the user will subscribe to correct topics
      if _.isEmpty pushTokens
        pushTokens = [{userId, deviceId: 'none', token: 'none'}]

      Promise.all _.map pushTokens, (token) =>
        upsertTopic = _.defaults {
          token: token.token
          deviceId: token.deviceId
        }, topic
        Promise.all _.filter [
          PushTopic.upsert upsertTopic
          unless token.token is 'none'
            @subscribeToTopicByToken token.token, upsertTopic
        ]

  subscribeToGroupTopics: ({userId, groupId}) =>
    Promise.all [
      @subscribeToPushTopic {
        userId
        groupId
      }
      @subscribeToPushTopic {
        userId
        groupId
        sourceType: 'role'
        sourceId: 'everyone'
      }
    ]
    # 'everyone'

  subscribeToTopicByToken: (token, topic) =>
    if token is 'none'
      return Promise.resolve null

    if typeof topic is 'object'
      topic = @getTopicStrFromPushTopic topic

    # if (config.ENV isnt config.ENVS.PROD or config.IS_STAGING)
    #   return Promise.resolve null

    base = 'https://iid.googleapis.com/iid/v1'
    request "#{base}/#{token}/rel/topics/#{topic}", {
      json: true
      method: 'POST'
      headers:
        'Authorization': "key=#{config.GOOGLE_API_KEY}"
      body: {}
    }
    .catch (err) ->
      console.log 'sub topic err', "#{base}/#{token}/rel/topics/#{topic}"

  unsubscribeToTopicByPushTopic: (pushTopic) =>
    topic = @getTopicStrFromPushTopic pushTopic
    base = 'https://iid.googleapis.com/iid/v1'

    PushToken.getAllByUserId pushTopic.userId
    .map (pushToken) ->
      request "#{base}/#{pushToken.token}/rel/topics/#{topic}", {
        json: true
        method: 'DELETE'
        headers:
          'Authorization': "key=#{config.GOOGLE_API_KEY}"
        body: {}
      }
    .catch (err) ->
      console.log 'unsub topic err', "#{base}/token/rel/topics/#{topic}"

  getTopicStrFromPushTopic: ({groupId, sourceType, sourceId}) ->
    sourceType ?= 'all'
    sourceId ?= 'all'
    # : not a valid topic character
    "#{groupId}~#{sourceType}~#{sourceId}"

module.exports = new PushNotificationService()
