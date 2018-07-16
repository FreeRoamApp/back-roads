_ = require 'lodash'

# sort of like zorium
isComponent = (x) ->
  _.isObject(x) and _.isFunction(x.render)

isChild = (x) ->
  _.isString(x) or
  isComponent(x) or
  _.isNumber(x) or
  Boolean x.tagName

isChildren = (x) ->
  _.isArray(x) or isChild(x)

parseZfuncArgs = (tagName, children...) ->
  props = {}

  # children[0] is attributes
  if children[0] and not isChildren children[0]
    props = children[0]
    children.shift()

  if children[0] and _.isArray children[0]
    children = children[0]

  if _.isObject tagName
    return {child: tagName.render(props), props}

  return {tagName, props, children}

module.exports = ->
  {child, tagName, props, children} = parseZfuncArgs.apply null, arguments

  if child?
    return child

  return {child, tagName, props, children}
