_ = require 'lodash'
Promise = require 'bluebird'

config = require '../config'
cknex = require '../services/cknex'

EmbedClasses =
  user: require '../embeds/user'

TYPES =
  # formatting of string is important. embedClassName:embedKeyAndFn
  USER:
    DATA: 'user:data'

embedFn = _.curry (props, object) ->
  {embed, options} = props
  embedded = _.cloneDeep object
  unless embedded
    return Promise.resolve null

  embedded.embedded = embed
  _.forEach embed, (key) ->
    [embedClassKey, embedKey] = key.split ':'
    embedded[embedKey] = EmbedClasses[embedClassKey][embedKey] options

  return Promise.props embedded

class EmbedService
  TYPES: TYPES
  embed: embedFn

module.exports = new EmbedService()
