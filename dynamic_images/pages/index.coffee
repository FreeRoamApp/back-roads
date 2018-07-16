Rsvg = require('librsvg').Rsvg
fs = require 'fs'

toHTML = require 'vdom-to-html'

s = require '../components/s'

# FIXME FIXME: get custom fonts working

module.exports = class Page
  render: =>
    @setup().then (props) =>
      width = props.width or 500
      height = props.height or 100
      $svg = s 'svg', {width, height},
        @renderHead props
        s(@$component, props)

      svgText = toHTML($svg)
      svg = new Rsvg svgText
      svg.render({
        format: 'png'
        width: width
        height: height
      }).data
