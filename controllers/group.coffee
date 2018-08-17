_ = require 'lodash'
router = require 'exoid-router'
Promise = require 'bluebird'

User = require '../models/user'
Group = require '../models/group'
GroupUser = require '../models/group_user'
GroupRole = require '../models/group_role'
Conversation = require '../models/conversation'
EmbedService = require '../services/embed'
CacheService = require '../services/cache'
PushNotificationService = require '../services/push_notification'
config = require '../config'

defaultEmbed = [
  # EmbedService.TYPES.GROUP.ME_GROUP_USER
  # EmbedService.TYPES.GROUP.STAR
  EmbedService.TYPES.GROUP.USER_COUNT
]
userDataEmbed = [
  EmbedService.TYPES.USER.DATA
]

THIRTY_MINUTES_SECONDS = 60 * 5

class GroupCtrl
  create: ({name, description, badgeUuid, background, mode}, {user}) ->
    Group.create {
      name, description, badgeUuid, background, mode
    }
    .tap ({uuid}) ->
      Promise.all [
        Group.addUser uuid, user.uuid
        GroupRole.upsert {
          groupUuid: uuid
          name: 'everyone'
          globalPermissions: {}
        }
        Conversation.upsert {
          groupUuid: uuid
          data:
            name: 'general'
          type: 'channel'
        }
      ]

  updateByUuid: ({uuid, name, description, badgeUuid, background, mode}, {user}) ->
    Group.hasPermissionByUuidAndUserUuid uuid, user.uuid, {level: 'admin'}
    .then (hasPermission) ->
      unless hasPermission
        router.throw {status: 400, info: 'You don\'t have permission'}

      Group.updateByUuid uuid, {name, description, badgeUuid, background, mode}

  leaveByUuid: ({uuid}, {user}) ->
    groupUuid = uuid
    userUuid = user.uuid

    unless groupUuid
      router.throw {status: 404, info: 'Group not found'}

    Group.getByUuid groupUuid
    .then (group) ->
      unless group
        router.throw {status: 404, info: 'Group not found'}

      Group.removeUser groupUuid, userUuid

  joinByUuid: ({uuid, id}, {user}) ->
    console.log 'join group', uuid, id
    userUuid = user.uuid

    unless uuid or id
      router.throw {status: 404, info: 'Group not found'}

    (if uuid
      Group.getByUuid uuid
    else
      Group.getById id
    ).then (group) ->
      unless group
        router.throw {status: 404, info: 'Group not found'}

      if group.privacy is 'private' and group.invitedUuids.indexOf(userUuid) is -1
        router.throw {status: 401, info: 'Not invited'}

      name = User.getDisplayName user

      # if group.type isnt 'public'
      #   PushNotificationService.sendToGroupTopic(group, {
      #     titleObj:
      #       key: 'newGroupMember.title'
      #     textObj:
      #       key: 'newGroupMember.text'
      #       replacements: {name}
      #     type: PushNotificationService.TYPES.GROUP
      #     url: "https://#{config.CLIENT_HOST}"
      #     path:
      #       key: 'groupChat'
      #       params:
      #         id: group.id
      #         gameKey: config.DEFAULT_GAME_KEY
      #   }, {skipMe: true, meUserUuid: user.uuid}).catch -> null

      console.log 'add', group.uuid, userUuid

      Group.addUser group.uuid, userUuid
      .then ->
        PushNotificationService.subscribeToGroupTopics {
          userUuid, groupUuid: group.id
        }

        prefix = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY
        category = "#{prefix}:#{userUuid}"
        CacheService.deleteByCategory category

  sendNotificationByUuid: ({title, description, pathKey, uuid}, {user}) ->
    groupUuid = uuid
    pathKey or= 'groupHome'

    # GroupUser.hasPermissionByGroupUuidAndUser groupUuid, user, permissions
    Group.getByUuid groupUuid
    .then (group) ->
      Group.hasPermission group, user, {level: 'admin'}
      .then (hasPermission) ->
        unless hasPermission
          router.throw status: 400, info: 'no permission'
        PushNotificationService.sendToGroupTopic group, {
          title: title
          text: description
          type: PushNotificationService.TYPES.NEWS
          data:
            path:
              key: pathKey
              params:
                groupUuid: groupUuid
        }

  getAllByUserUuid: ({language, user, userUuid, embed}) ->
    embed = _.map embed, (item) ->
      EmbedService.TYPES.GROUP[_.snakeCase(item).toUpperCase()]

    (if user
      Promise.resolve user
    else
      User.getByUuid userUuid
    ).then (user) ->
      key = CacheService.PREFIXES.GROUP_GET_ALL + ':' + [
        user.uuid, 'mine_lite', language, embed.join(',')
      ].join(':')
      category = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY + ':' + user.uuid

      CacheService.preferCache key, ->
        GroupUser.getAllByUserUuid user.uuid, {preferCache: true}
        .map ({groupUuid}) -> groupUuid
        .then (groupUuids) ->
          Group.getAllByUuids groupUuids
        .map EmbedService.embed {embed, options: {user}}
      , {
        expireSeconds: THIRTY_MINUTES_SECONDS
        category: category
      }

  getAll: ({filter, language, embed}, {user}) =>
    embed = _.map embed, (item) ->
      EmbedService.TYPES.GROUP[_.snakeCase(item).toUpperCase()]
    key = CacheService.PREFIXES.GROUP_GET_ALL + ':' + [
      user.uuid, filter, language, embed.join(',')
    ].join(':')
    category = CacheService.PREFIXES.GROUP_GET_ALL_CATEGORY + ':' + user.uuid

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

  getAllChannelsByUuid: ({uuid}, {user}) ->
    GroupUser.getByGroupUuidAndUserUuid(
      uuid, user.uuid
    )
    .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}
    .then (meGroupUser) ->
      Conversation.getAllByGroupUuid uuid
      .then (conversations) ->
        _.filter conversations, (conversation) ->
          GroupUser.hasPermission {
            meGroupUser
            permissions: [GroupUser.PERMISSIONS.MANAGE_CHANNEL]
            channelUuid: conversation.uuid
            me: user
          }

  _setupGroup: (group, {autoJoin, user}) =>
    EmbedService.embed {embed: defaultEmbed, options: {user}}, group
    .then (group) =>
      getGroupUser = ->
        GroupUser.getByGroupUuidAndUserUuid group.uuid, user.uuid
        .then EmbedService.embed {embed: [EmbedService.TYPES.GROUP_USER.ROLES]}

      getGroupUser()
      .then (groupUser) =>
        if groupUser.userUuid
          groupUser
        else
          @joinByUuid {uuid: group.uuid}, {user}
          .then getGroupUser
      .then (groupUser) ->
        group.meGroupUser = groupUser
        group

  getByUuid: ({uuid, autoJoin}, {user}) =>
    Group.getByUuid uuid
    .then (group) =>
      unless group
        console.log 'missing group uuid', uuid
        return
      @_setupGroup group, {autoJoin, user}

  getById: ({id, autoJoin}, {user}) =>
    console.log 'get group'
    Group.getById id
    .then (group) =>
      console.log 'group', group
      unless group
        console.log 'missing group id', id
        return
      @_setupGroup group, {autoJoin, user}

module.exports = new GroupCtrl()
