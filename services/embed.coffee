_ = require 'lodash'
Promise = require 'bluebird'

config = require '../config'
cknex = require '../services/cknex'

EmbedClasses =
  user: require '../embeds/user'
  category: require '../embeds/category'
  group: require '../embeds/group'
  groupAuditLog: require '../embeds/group_audit_log'
  groupUser: require '../embeds/group_user'
  item: require '../embeds/item'
  product: require '../embeds/product'
  thread: require '../embeds/thread'
  threadComment: require '../embeds/thread_comment'

TYPES =
  # formatting of string is important. embedClassName:embedKeyAndFn
  USER:
    DATA: 'user:data'
  CATEGORY:
    FIRST_ITEM_PRODUCT_ID: 'category:firstItemFirstProductId'
  CONVERSATION_MESSAGE:
    USER: 'conversationMessage:user'
    MENTIONED_USERS: 'conversationMessage:mentionedUsers'
    GROUP_USER: 'conversationMessage:groupUser'
    TIME: 'conversationMessage:time'
  CONVERSATION:
    USERS: 'conversation:users'
    LAST_MESSAGE: 'conversation:lastMessage'
  GROUP:
    USER_COUNT: 'group:userCount'
    USERS: 'group:users'
    ME_GROUP_USER: 'group:group_user'
  GROUP_AUDIT_LOG:
    USER: 'groupAuditLog:user'
    TIME: 'groupAuditLog:time'
  GROUP_USER:
    ROLES: 'groupUser:roles'
    ROLE_NAMES: 'groupUser:roleNames'
    KARMA: 'groupUser:karma'
    USER: 'groupUser:user'
  ITEM:
    FIRST_PRODUCT_ID: 'item:firstProductId'
  PRODUCT:
    NAME_KEBAB: 'product:nameKebab'
    ITEM: 'product:item'
  THREAD_COMMENT:
    USER: 'threadComment:user'
    GROUP_USER: 'threadComment:groupUser'
    TIME: 'threadComment:time'
  THREAD:
    USER: 'thread:user'
    COMMENT_COUNT: 'thread:commentCount'

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
    try
      embedded[embedKey] = EmbedClasses[embedClassKey][embedKey] embedded, options
    catch err
      console.log key, err

  return Promise.props embedded

class EmbedService
  TYPES: TYPES
  embed: embedFn

module.exports = new EmbedService()
