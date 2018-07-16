toHTML = require 'vdom-to-html'

module.exports = class Component
  toString: =>
    Promise.resolve @render()
    .then toHTML

  render: ->
    console.log 'render not defined'
