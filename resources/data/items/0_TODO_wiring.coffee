# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

module.exports = {items: [], products: []} # FIXME
return

item =
  slug: 'wiring'
  id: '11a87340-b4c5-11e9-b6a9-313977c8e13a'
  name: 'Wiring'
  categories: ['boondocking']
  why: ''
  # what: ''
  decisions: [
    {
      title: 'Mounted vs portable'
      text: """
Mounting solar panels on your roof means more upfront work, but less work over time. You can also continue charginging your batteries while driving. With portable panels, you'll have to bring them outside and set them up when you want to charge, but have the advantage that you can put them where they'll get the most sun.
"""
    }
  ]
  videos: [
    # {sourceType: 'youtube', sourceId: '4-OpzH5sBG4', name: 'How many watts to get'}
  ]


products =
  "renogy-100w-solar-panel-mono":
    name: 'Renogy 100W Solar Panel'
    description: '''
Renogy is the most well-known brand of RV solar panels, and these are good panels that are priced well
'''
    itemSlug: 'solar-panel'
    source: 'amazon'
    sourceId: 'B009Z6CW7O'
    reviewersLiked: ['Quality material', 'Priced well']
    reviewersDisliked: ['Sharp edges', 'Small percent of units arrived damaged (glass)']
    decisions: ['Mounted', '100W', 'Mono']


module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
