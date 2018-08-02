_ = require 'lodash'
Promise = require 'bluebird'

config = require '../config'
cknex = require '../services/cknex'

EmbedClasses =
  user: require '../embeds/user'
  item: require '../embeds/item'
  product: require '../embeds/product'

TYPES =
  # formatting of string is important. embedClassName:embedKeyAndFn
  USER:
    DATA: 'user:data'
  PRODUCT:
    NAME_KEBAB: 'product:nameKebab'
    ITEM: 'product:item'
  ITEM:
    FIRST_PRODUCT_ID: 'item:firstProductId'

embedFn = _.curry (props, object) ->
  {embed, options} = props
  embedded = _.cloneDeep object
  unless embedded
    return Promise.resolve null

  embedded.embedded = embed
  _.forEach embed, (key) ->
    [embedClassKey, embedKey] = key.split ':'
    console.log 'embed', embedKey
    embedded[embedKey] = EmbedClasses[embedClassKey][embedKey] embedded, options

  return Promise.props embedded

class EmbedService
  TYPES: TYPES
  embed: embedFn

module.exports = new EmbedService()
