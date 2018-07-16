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
Event = require '../models/event'
Group = require '../models/group'
GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
Language = require '../models/language'
UserBlock = require '../models/user_block'
StatsService = require './stats'

ONE_DAY_SECONDS = 3600 * 24
RETRY_COUNT = 10
CONSECUTIVE_ERRORS_UNTIL_INACTIVE = 10
MAX_INT_32 = 2147483647

TYPES =
  NEW_PROMOTION: 'sale'
  NEWS: 'news'
  DAILY_RECAP: 'dailyRecap'
  EVENT: 'event'
  CHAT_MESSAGE: 'chatMessage'
  CHAT_MENTION: 'chatMention'
  PRIVATE_MESSAGE: 'privateMessage'
  NEW_FRIEND: 'newFriend'
  PRODUCT: 'product'
  GROUP: 'group'
  STATUS: 'status'
  TRADE: 'trade'
  VIDEO: 'video'

defaultUserEmbed = [
  EmbedService.TYPES.USER.GROUP_USER_SETTINGS
]
cdnUrl = "https://#{config.CDN_HOST}/d/images/freeroam"

class PushNotificationService
  constructor: ->
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
              @TYPES.CHAT_MESSAGE
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

      @gcmConn.send notification, toObj, RETRY_COUNT, (err, result) ->
        successes = result?.success or result?.message_id
        if err or not successes
          reject err
        else
          resolve true

  sendToConversation: (conversation, options = {}) =>
    {skipMe, meUser, text, mentionUserIds, mentionRoles, chatMessage} = options

    mentionUserIds ?= []
    (if conversation.groupId
      Group.getById "#{conversation.groupId}"
      .then (group) -> {group}
    else if conversation.eventId
      Event.getById conversation.eventId
      .then (event) -> {event}
    else
      Promise.resolve {userIds: conversation.userIds}
    ).then ({group, event, userIds}) =>
      if event
        return # TODO: re-enable

      if group
        path = {
          key: 'groupChatConversation'
          params:
            groupId: group.key or group.id
            conversationId: conversation.id
            gameKey: config.DEFAULT_GAME_KEY
          qs:
            minTimeUuid: chatMessage?.timeUuid
        }
      else if event
        path = {
          key: 'event'
          params:
            id: event.id
            gameKey: config.DEFAULT_GAME_KEY
        }
      else
        path = {
          key: 'conversation'
          params:
            id: conversation.id
            gameKey: config.DEFAULT_GAME_KEY
        }

      message =
        title: event?.name or group?.name or User.getDisplayName meUser
        type: if group or event \
              then @TYPES.CHAT_MESSAGE
              else @TYPES.PRIVATE_MESSAGE
        text: if group or event \
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

  sendToEvent: (event, message, {skipMe, fromUserId, eventId} = {}) =>
    @sendToUserIds event.userIds, message, {skipMe, fromUserId, eventId}

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
          user = user.then EmbedService.embed {embed: defaultUserEmbed, groupId}
        user
        .then (user) =>
          @send user, message, {fromUserId, groupId, conversation}

  send: (user, message, {fromUserId, groupId, conversation} = {}) =>
    unless message and (
      message.title or message.text or message.titleObj or message.textObj
    )
      return Promise.reject new Error 'missing message'

    StatsService.sendEvent user.id, 'push_notification', message.type, 'send'

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
        if message.groupId
          groupAppKey = _.find(config.GROUPS, {ID: message.groupId})?.APP_KEY
          groupAppToken = _.find tokens, {appKey: config.GROUPS.MAIN.APP_KEY}
          if groupAppToken
            return groupAppToken
        mainAppToken = _.find tokens, {appKey: config.GROUPS.MAIN.APP_KEY}
        if mainAppToken
          return mainAppToken
        return tokens[0]

      Promise.map pushTokens, (pushToken) =>
        {id, sourceType, token, errorCount} = pushToken
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

          if newErrorCount >= CONSECUTIVE_ERRORS_UNTIL_INACTIVE
            PushToken.getAllByUserId user.id
            .then (tokens) ->
              if _.isEmpty tokens
                User.updateById user.id, {
                  hasPushToken: false
                }

  _checkIfBlocked: (user, fromUserId) ->
    if fromUserId
      UserBlock.getAllByUserId user.id
      .then (blockedUsers) ->
        isBlocked = _.find blockedUsers, {blockedId: fromUserId}
        if isBlocked
          throw new Error 'user blocked'
    else
      Promise.resolve()

  subscribeToAllUserTopics: ({userId, appKey, token, deviceId}) ->
    isMainApp = appKey is config.GROUPS.MAIN.APP_KEY
    appGroupId = _.find(config.GROUPS, {APP_KEY: appKey})?.ID

    Promise.all [
      PushToken.getAllByUserId userId
      PushTopic.getAllByUserId userId
    ]
    .then ([pushTokens, pushTopics]) =>
      appKeyPushTokens = _.filter pushTokens, {appKey}
      appKeyPushTopics = _.filter pushTopics, {appKey}

      if isMainApp
        mainAppTopics = _.filter pushTopics, {
          appKey: config.GROUPS.MAIN.APP_KEY
        }
        uniqueMainAppTopics = _.uniqBy mainAppTopics, (topic) ->
          _.omit topic, ['token']
        Promise.map uniqueMainAppTopics, (topic) =>
          @subscribeToTopicByToken token, topic
          .then ->
            PushTopic.upsert _.defaults {
              token: token
              deviceId: deviceId
            }, topic
      else if appGroupId
        mainAppGroupTopics = _.filter pushTopics, {
          appKey: config.GROUPS.MAIN.APP_KEY
          groupId: appGroupId
        }
        uniqueMainAppGroupTopics = _.uniqBy mainAppGroupTopics, (topic) ->
          _.omit topic, ['token']
        # move main app subscription topics to this appKey
        # delete/unsub all main app id ones
        Promise.map mainAppGroupTopics, (topic) =>
          @unsubscribeToTopicByPushTopic topic
          .then ->
            PushTopic.deleteByPushTopic topic

        # move main app id ones to group app
        Promise.map uniqueMainAppGroupTopics, (topic) =>
          newTopic = _.defaults {appKey}, topic
          Promise.map appKeyPushTokens, (pushToken) =>
            @subscribeToTopicByToken pushToken.token, topic
            .then ->
              PushTopic.upsert _.defaults {
                token: pushToken.token
                deviceId: pushToken.deviceId
              }, newTopic

  _getBestTokens: ({pushTokens, appKey, groupId}) ->
    groupAppKey = _.find(config.GROUPS, {ID: groupId})?.APP_KEY

    deviceIds = _.groupBy pushTokens, 'deviceId'
    bestTokens = _.mapValues deviceIds, (tokens, deviceId) ->
      # check if one for appKey (app currently being used) exists
      appKeyToken = _.find tokens, {appKey, errorCount: 0}
      if appKey and appKeyToken
        return appKeyToken

      # check for group app
      groupAppKeyToken = _.find tokens, {appKey: groupAppKey, errorCount: 0}
      if groupAppKeyToken
        return groupAppKeyToken

      # main fr app
      mainAppKeyToken = _.find tokens, {
        appKey: config.GROUPS.MAIN.APP_KEY, errorCount: 0
      }
      if mainAppKeyToken
        return mainAppKeyToken

      noErrorToken = _.find tokens, {errorCount: 0}
      if noErrorToken
        return noErrorToken

      return tokens[0]

  # go through all pushTokens a user has and subscribe them to the topic.
  # max 1 subscription per device,
  # prefer the app they're currently using (appKey, then the group appKey)
  subscribeToPushTopic: (topic) =>
    {userId, groupId, appKey, sourceType, sourceId} = topic

    Promise.all [
      PushToken.getAllByUserId userId
      PushTopic.getAllByUserId userId
    ]
    .then ([pushTokens, topics]) =>
      # still store push topics if a token isn't set, that way when one does get
      # set, the user will subscribe to correct topics
      if _.isEmpty pushTokens
        pushTokens = [{userId, appKey, deviceId: 'none', token: 'none'}]

      bestTokens = @_getBestTokens {pushTokens, appKey, groupId}

      Promise.all _.map bestTokens, (token) =>
        upsertTopic = _.defaults {
          token: token.token
          deviceId: token.deviceId
        }, topic
        Promise.all _.filter [
          PushTopic.upsert upsertTopic
          unless token.token is 'none'
            @subscribeToTopicByToken token.token, upsertTopic
        ]

  subscribeToGroupTopics: ({userId, groupId, appKey}) =>
    Promise.all [
      @subscribeToPushTopic {
        userId
        groupId
        appKey
      }
      @subscribeToPushTopic {
        userId
        groupId
        appKey
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
