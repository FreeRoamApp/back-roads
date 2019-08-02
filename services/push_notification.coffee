###
TODO:
- deploy first
  - test
  - then create subscriptions for existing users

x login should delete all other subscriptions for that deviceId/token!
  x need to store subscriptions by token for that to work

TEST:
x new user subscribe
- login deletes all other subscriptions
  - FIXME: not working
- push notifications on my phone and rachel's (same account)

  -
###

_ = require 'lodash'
apn = require 'apn'
gcm = require 'node-gcm'
Promise = require 'bluebird'
uuid = require 'node-uuid'
webpush = require 'web-push'
request = require 'request-promise'
randomSeed = require 'random-seed'

config = require '../config'
Conversation = require '../models/conversation'
User = require '../models/user'
Notification = require '../models/notification'
PushToken = require '../models/push_token'
Subscription = require '../models/subscription'
Group = require '../models/group'
GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
Language = require '../models/language'
UserBlock = require '../models/user_block'

ONE_DAY_SECONDS = 3600 * 24
RETRY_COUNT = 10
CONSECUTIVE_ERRORS_UNTIL_INACTIVE = 10
MAX_INT_32 = 2147483647

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

  sendFcm: (to, message, {isiOS} = {}) =>
    {title, text, type, data, icon, toType, notId, style, summaryText} = message
    toType ?= 'token'
    new Promise (resolve, reject) =>
      messageOptions = {
        priority: 'high'
        contentAvailable: true
      }
      # ios and android take different formats for whatever reason...
      # if you pass notification to android, it uses that and doesn't use data
      # https://github.com/phonegap/phonegap-plugin-push/issues/387

      if isiOS # only toType token, topics are different
        messageOptions.notification =
          title: title
          body: text
          # icon: 'notification_icon'
          color: config.NOTIFICATION_COLOR
        messageOptions.data = data
      else # for android, and all push topics
        ###
        TODO: look into this some more.
        when sending to pushTopics, it needs to work for both iOS and Android.
        This option sort of works, but sending as a data notification is more
        advantageous for android. Otherwise notification actions don't work,
        the callback isn't called in app, so android
        doesn't get sent to right page (ios does).
        But sending as data notification means iOS
        gets nothing... Solution is probably to use something other than
        phonegap-plugin-push??? As of 8/2019 I don't see anything
        ###
        key = if toType is 'topic' then 'notification' else 'data'
        messageOptions[key] =
          title: title
          body: text # nec when we're setting messageOptions.notification
          message: text
          ledColor: [0, 255, 0, 0]
          image: if icon then icon else null
          payload: data # android
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
              Subscription.TYPES.CHANNEL_MESSAGE
              Subscription.TYPES.CHANNEL_MENTION
              Subscription.TYPES.PRIVATE_MESSAGE
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
          style: style
          summaryText: summaryText
          # android_channel_id: 'test'

      notification = new gcm.Message messageOptions

      if toType is 'token'
        toObj = {registrationTokens: [to]}
      else if toType is 'topic' and to
        toObj = {topic: "/topics/#{to}"}
        # toObj = {condition: "'#{to}' in topics || '#{to}2' in topics"}

      console.log 'try gcm', toObj
      @gcmConn.send notification, toObj, RETRY_COUNT, (err, result) ->
        console.log 'gcm response', err, result
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
              then Subscription.TYPES.CHANNEL_MESSAGE
              else Subscription.TYPES.PRIVATE_MESSAGE
        text: if group \
              then "#{User.getDisplayName(meUser)}: #{text}"
              else text
        url: "https://#{config.FREE_ROAM_HOST}"
        icon: if group \
              then "#{cdnUrl}/groups/badges/#{group.badgeId}.png"
              else if meUser?.avatarImage?.prefix
              then "#{config.USER_CDN_URL}/#{meUser?.avatarImage?.prefix}.small.jpg"
              else undefined
        data:
          conversationId: conversation.id
          contextId: conversation.id
          path: path
        # ideally we'd group by conversation and use something like this:
        # https://github.com/phonegap/phonegap-plugin-push/issues/2514
        # BUT we'd need to solve the dupe notifications if sub'd to group
        # and channel first (don't allow sub to both)
        # notId: randomSeed.create(conversation.id)(MAX_INT_32)
        # summaryText: '%n% new messages'
        notId: randomSeed.create(conversationMessage?.id)(MAX_INT_32)

      mentionMessage = _.defaults {type: Subscription.TYPES.CHANNEL_MENTION}, message

      Promise.all [
        @sendToRoles mentionRoles, mentionMessage, {
          fromUserId: meUser.id, groupId: conversation.groupId
          conversation: conversation
        }

        @sendToUserIds mentionUserIds, mentionMessage, {
          skipMe, fromUserId: meUser.id, groupId: conversation.groupId
          conversation: conversation
        }

        # TODO: add group types
        if not group or group?.type is 'private'
          @sendToUserIds _.filter(userIds), message, {
            skipMe, fromUserId: meUser.id, groupId: conversation.groupId
            conversation: conversation
          }
        else
          Conversation.getAllPublicByGroupId group.id
          .then (publicChannels) =>
            if _.find publicChannels, {id: conversation.id}
              Promise.all [
                @sendToGroupTopic group, message
                @sendToChannelTopic conversation, message
              ]
      ]

  # topics are NOT secure. anyone can subscribe. for secure messaging, always
  # use the deviceToken. for private channels, use deviceToken

  sendToSubscription: (subscription, message, {language, forceDevSend} = {}) =>
    topic = Subscription.getTopicFromSubscription subscription

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
      notId: message.notId
      style: message.style
      summaryText: message.summaryText
    }

    if (config.ENV isnt config.ENVS.PROD or config.IS_STAGING) and
        not forceDevSend
      console.log 'send notification', subscription, topic, JSON.stringify message
      # return Promise.resolve()

    console.log 'send', topic

    @sendFcm topic, message


  sendToGroupTopic: (group, message) =>
    subscription = {
      groupId: group.id, sourceType: Subscription.TYPES.GROUP_MESSAGE
    }
    @sendToSubscription subscription, message

  sendToChannelTopic: (channel, message) =>
    subscription = {
      groupId: channel.groupId, sourceType: Subscription.TYPES.CHANNEL_MESSAGE
      sourceId: channel.id
    }
    @sendToSubscription subscription, message

  sendToRoles: (roles, message, {groupId} = {}) ->
    Promise.map roles, (role) =>
      console.log 'send role', role
      subscription = {
        groupId, sourceType: Subscription.TYPES.GROUP_ROLE, sourceId: role
      }
      @sendToSubscription subscription, message

  sendToUserIds: (userIds, message, options = {}) ->
    {skipMe, fromUserId, groupId, conversation} = options
    Promise.each userIds, (userId) =>
      unless "#{userId}" is "#{fromUserId}"
        User.getById userId, {preferCache: true}
        .then (user) =>
          (if conversation.type is 'pm'
            Promise.resolve true
          else
            GroupUser.hasPermissionByGroupIdAndUser groupId, user, [
              GroupUser.PERMISSIONS.READ_MESSAGE
            ], {channelId: conversation.id}
          ).then (hasPermission) =>
            if hasPermission
              @send user, message, {fromUserId, groupId, conversation}

  send: (user, message, {fromUserId, groupId, conversation} = {}) =>
    unless message and (
      message.title or message.text or message.titleObj or message.textObj
    )
      return Promise.reject new Error 'missing message'

    language = user.language or 'en'

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

    notificationData = {path: message.data.path, type: message.type}
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

    isChannel = message.type.indexOf('channel') is 0
    # TODO: bypass this if sending in bulk
    Promise.all [
      Subscription.getByRow {
        userId: user.id
        groupId: groupId or config.EMPTY_UUID
        sourceType: message.type
        sourceId: if isChannel then conversation.id else 'all'
      }
      if isChannel
        Subscription.getByRow {
          userId: user.id
          groupId: groupId or config.EMPTY_UUID
          sourceType: message.type.replace 'channel', 'group'
        }
    ]
    .then ([channelSubscription, groupSubscription]) =>
      console.log 'attempt send', message.type, Boolean channelSubscription
      if not channelSubscription?.isEnabled and not groupSubscription?.isEnabled
        console.log 'no push subscription', message.type
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
          # could also do minBy errorCount
          _.maxBy tokens, 'time'

        Promise.map pushTokens, (pushToken) =>
          {sourceType, userId, token, errorCount} = pushToken
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
            console.log 'caught error', newErrorCount
            if newErrorCount >= CONSECUTIVE_ERRORS_UNTIL_INACTIVE
              Promise.all [
                PushToken.deleteByPushToken pushToken
                Subscription.removeTokenByUserId userId, token
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

module.exports = new PushNotificationService()
