_ = require 'lodash'
Promise = require 'bluebird'

config = require '../config'
cknex = require '../services/cknex'

EmbedClasses =
  amenity: require '../embeds/amenity'
  attachment: require '../embeds/attachment'
  ban: require '../embeds/ban'
  category: require '../embeds/category'
  campground: require '../embeds/campground'
  checkIn: require '../embeds/check_in'
  connection: require '../embeds/connection'
  conversation: require '../embeds/conversation'
  conversationMessage: require '../embeds/conversation_message'
  event: require '../embeds/event'
  group: require '../embeds/group'
  groupAuditLog: require '../embeds/group_audit_log'
  groupUser: require '../embeds/group_user'
  item: require '../embeds/item'
  overnight: require '../embeds/overnight'
  product: require '../embeds/product'
  review: require '../embeds/review'
  thread: require '../embeds/thread'
  threadComment: require '../embeds/comment'
  trip: require '../embeds/trip'
  tripFollower: require '../embeds/trip_follower'
  user: require '../embeds/user'
  userBlock: require '../embeds/user_block'
  userLocation: require '../embeds/user_location'

TYPES =
  # formatting of string is important. embedClassName:embedKeyAndFn
  AMENITY:
    ATTACHMENTS_PREVIEW: 'amenity:attachmentsPreview'
  ATTACHMENT:
    TIME: 'attachment:time'
    USER: 'attachment:user'
  BAN:
    USER: 'ban:user'
    BANNED_BY_USER: 'ban:bannedByUser'
  CATEGORY:
    ITEM_NAMES: 'category:itemNames'
  CAMPGROUND:
    ATTACHMENTS_PREVIEW: 'campground:attachmentsPreview'
  CHECK_IN:
    PLACE: 'checkIn:place'
  CONNECTION:
    USER: 'connection:user'
    OTHER: 'connection:other'
  CONVERSATION_MESSAGE:
    USER: 'conversationMessage:user'
    MENTIONED_USERS: 'conversationMessage:mentionedUsers'
    GROUP_USER: 'conversationMessage:groupUser'
    TIME: 'conversationMessage:time'
  CONVERSATION:
    USERS: 'conversation:users'
    LAST_MESSAGE: 'conversation:lastMessage'
  EVENT:
    ATTACHMENTS_PREVIEW: 'event:attachmentsPreview'
  GROUP:
    USER_COUNT: 'group:userCount'
    USERS: 'group:users'
    CHANNELS: 'group:channels'
    ME_GROUP_USER: 'group:meGroupUser'
  GROUP_AUDIT_LOG:
    USER: 'groupAuditLog:user'
    TIME: 'groupAuditLog:time'
  GROUP_USER:
    ROLES: 'groupUser:roles'
    ROLE_NAMES: 'groupUser:roleNames'
    USER: 'groupUser:user'
  ITEM:
    PRODUCT_SLUGS: 'item:productSlugs'
  OVERNIGHT:
    ATTACHMENTS_PREVIEW: 'overnight:attachmentsPreview'
  PRODUCT:
    NAME_KEBAB: 'product:nameKebab'
    ITEM: 'product:item'
  REVIEW:
    EXTRAS: 'review:extras'
    TIME: 'review:time'
    USER: 'review:user'
    PARENT: 'review:parent'
  COMMENT:
    USER: 'threadComment:user'
    GROUP_USER: 'threadComment:groupUser'
    TIME: 'threadComment:time'
  THREAD:
    USER: 'thread:user'
    COMMENT_COUNT: 'thread:commentCount'
  TRIP:
    CHECK_INS: 'trip:checkIns'
    ROUTE: 'trip:route'
    STATS: 'trip:stats'
    OVERVIEW: 'trip:overview'
    USER: 'trip:user'
  TRIP_FOLLOWER:
    TRIP: 'tripFollower:trip'
    USER: 'tripFollower:user'
  USER:
    KARMA: 'user:karma'
    DATA: 'user:data'
  USER_BLOCK:
    USER: 'userBlock:user'
  USER_LOCATION:
    PLACE: 'userLocation:place'
    USER: 'userLocation:user'

embedFn = _.curry (props, object) ->
  {embed, options} = props
  embedded = _.cloneDeep object
  unless embedded
    return Promise.resolve null

  embedded.embedded = embed
  _.forEach embed, (key) ->
    unless key
      console.log 'missing embed', props, object
    [embedClassKey, embedKey] = key.split ':'
    embedded[embedKey] = EmbedClasses[embedClassKey][embedKey](
      embedded, options
    )

  return Promise.props embedded

class EmbedService
  TYPES: TYPES
  embed: embedFn

module.exports = new EmbedService()
