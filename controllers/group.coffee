_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

User = require '../models/user'
Group = require '../models/group'
GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
Conversation = require '../models/conversation'
ConversationMessage = require '../models/conversation_message'
Language = require '../models/language'
Subscription = require '../models/subscription'
EmbedService = require '../services/embed'
CacheService = require '../services/cache'
ConversationMessageService = require '../services/conversation_message'
PushNotificationService = require '../services/push_notification'
config = require '../config'

defaultEmbed = [
  # EmbedService.TYPES.GROUP.ME_GROUP_USER
  # EmbedService.TYPES.GROUP.STAR
  # EmbedService.TYPES.GROUP.USER_COUNT
]
userDataEmbed = [
  EmbedService.TYPES.USER.DATA
]

THIRTY_MINUTES_SECONDS = 60 * 5

class GroupCtrl
  create: ({name, description, badgeId, background, mode}, {user}) ->
    Group.create {
      name, description, badgeId, background, mode
    }
    .tap (group) ->
      {id} = group
      Promise.all [
        Group.addUser id, user.id
        GroupRole.upsert {
          groupId: id
          name: 'everyone'
          globalPermissions: {}
        }
        Conversation.upsert {
          groupId: id
          data:
            name: 'general'
          type: 'channel'
        }
        .then (conversation) ->
          Group.upsertByRow group, {
            data:
              _.defaults {
                welcomeChannelId: conversation.id
              }, group.data
          }
      ]

  updateById: ({id, name, description}, {user}) ->
    Promise.all [
      GroupUser.hasPermissionByGroupIdAndUser id, user, [
        GroupUser.PERMISSIONS.MANAGE_INFO
      ]
      Group.getById id
    ]
    .then ([hasPermission, group]) ->
      unless hasPermission
        router.throw {status: 400, info: 'You don\'t have permission'}

      Group.upsertByRow group, {name, description}

  leaveById: ({id}, {user}) ->
    groupId = id
    userId = user.id

    unless groupId
      router.throw {status: 404, info: 'Group not found'}

    Group.getById groupId
    .then (group) ->
      unless group
        router.throw {status: 404, info: 'Group not found'}

      Group.removeUser groupId, userId

  joinById: ({id, slug}, {user}) ->
    userId = user.id

    unless id or slug
      router.throw {status: 404, info: 'Group not found'}

    (if id
      Group.getById id
    else
      Group.getBySlug slug
    ).then (group) ->
      unless group
        router.throw {status: 404, info: 'Group not found'}

      if group.privacy is 'private' and group.invitedIds.indexOf(userId) is -1
        router.throw {status: 401, info: 'Not invited'}

      name = User.getDisplayName user

      # if group.type isnt 'public'
      #   PushNotificationService.sendToGroupTopic(group, {
      #     titleObj:
      #       key: 'newGroupMember.title'
      #     textObj:
      #       key: 'newGroupMember.text'
      #       replacements: {name}
      #     type: Subscription.TYPES.SOCIAL
      #     url: "https://#{config.CLIENT_HOST}"
      #     path:
      #       key: 'groupChat'
      #       params:
      #         id: group.id
      #         gameKey: config.DEFAULT_GAME_KEY
      #   }, {skipMe: true, meUserId: user.id}).catch -> null


      Group.addUser group.id, userId
      .then ->
        Subscription.subscribeToGroup {
          userId, groupId: group.id
        }

        Conversation.getDefaultByGroup group
        .then (conversation) ->
          if conversation
            ConversationMessage.upsert {
              # id: conversationMessageId
              userId: userId
              body: Language.get "conversations.newUser", {
                file: 'strings'
              }
              # clientId: clientId
              conversationId: conversation.id
              groupId: group.id
              type: 'action'
            }, {
              prepareFn: ConversationMessageService.prepare
            }

        prefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
        category = "#{prefix}:#{userId}"
        CacheService.deleteByCategory category

  sendNotificationById: ({title, description, pathKey, id}, {user}) ->
    groupId = id
    pathKey or= 'groupHome'

    # GroupUser.hasPermissionByGroupIdAndUser groupId, user, permissions
    Group.getById groupId
    .then (group) ->
      Group.hasPermission group, user, {level: 'admin'}
      .then (hasPermission) ->
        unless hasPermission
          router.throw status: 400, info: 'no permission'
        PushNotificationService.sendToGroupTopic group, {
          title: title
          text: description
          type: Subscription.TYPES.NEWS
          data:
            path:
              key: pathKey
              params:
                groupId: groupId
        }

  getAllByUserId: ({language, user, userId, embed}) ->
    embed = _.map embed, (item) ->
      EmbedService.TYPES.GROUP[_.snakeCase(item).toUpperCase()]

    (if user
      Promise.resolve user
    else
      User.getById userId
    ).then (user) ->
      key = CacheService.PREFIXES.GROUP_GET_ALL + ':' + [
        user.id, 'mine_lite', language, embed.join(',')
      ].join(':')
      category = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY + ':' + user.id

      CacheService.preferCache key, ->
        GroupUser.getAllByUserId user.id, {preferCache: true}
        .map ({groupId}) -> groupId
        .then (groupIds) ->
          Group.getAllByIds groupIds
        .map EmbedService.embed {embed, options: {user}}
      , {
        expireSeconds: THIRTY_MINUTES_SECONDS
        category: category
      }

  getAll: ({filter, language, embed}, {user}) =>
    embed = _.map embed, (item) ->
      EmbedService.TYPES.GROUP[_.snakeCase(item).toUpperCase()]
    key = CacheService.PREFIXES.GROUP_GET_ALL + ':' + [
      user.id, filter, language, embed.join(',')
    ].join(':')
    category = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY + ':' + user.id

    CacheService.preferCache key, ->
      Group.getAll {filter, language}
      .then (groups) ->
        if filter is 'public' and _.isEmpty groups
          Group.getAll {filter}
        else
          groups
      .map EmbedService.embed {embed, options: {user}}
    , {
      expireSeconds: THIRTY_MINUTES_SECONDS
      category: category
    }

  getAllConversationsById: ({id}, {user}) ->
    GroupUser.getByGroupIdAndUserId(
      id, user.id
    )
    .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}
    .then (meGroupUser) ->
      Conversation.getAllByGroupId id
      .then (conversations) ->
        _.filter conversations, (conversation) ->
          GroupUser.hasPermission {
            meGroupUser
            permissions: [GroupUser.PERMISSIONS.MANAGE_CHANNEL]
            channelId: conversation.id
            me: user
          }

  _setupGroup: (group, {autoJoin, user}) =>
    EmbedService.embed {embed: defaultEmbed, options: {user}}, group
    .then (group) =>
      getGroupUser = ->
        GroupUser.getByGroupIdAndUserId group.id, user.id
        .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}

      getGroupUser()
      .then (groupUser) =>
        if groupUser.userId
          groupUser
        else if autoJoin
          @joinById {id: group.id}, {user}
          .then getGroupUser
      .then (groupUser) ->
        group.meGroupUser = groupUser
        group

  getById: ({id, autoJoin}, {user}) =>
    Group.getById id
    .then (group) =>
      unless group
        console.log 'missing group id', id
        return
      @_setupGroup group, {autoJoin, user}

  getBySlug: ({slug, autoJoin}, {user}) =>
    Group.getBySlug slug
    .then (group) =>
      unless group
        console.log 'missing group slug', slug
        return
      @_setupGroup group, {autoJoin, user}

module.exports = new GroupCtrl()
