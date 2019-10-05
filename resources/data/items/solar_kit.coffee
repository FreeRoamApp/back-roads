# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'solar-kit'
  id: '6aa62b30-b4c6-11e9-952b-8f9f939355df'
  name: 'Solar Kit'
  categories: ['boondocking']
  why: 'Solar panels are the easy, quiet version of powering your RV off-grid. As long as you have sun and a decent setup, you are fully self-sustaining.

You can go with a kit, or buy parts individually, but in either case it\'s a good idea to read the other product guides we have for individual parts: solar panels, batteries, charge controllers and cables.

If you do buy a kit, make sure it doesn\'t include what you already have. Eg. if you already have an inverter, get a kit without one.

The kits can be easier to get everything right, and usually come with good instructions, but sometimes they cost more than buying all parts individually, and you have less customization options. Most kits don\'t come with batteries.'
  # what: ''

  filters:
    rigType: ['motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some']

  decisions: [
    {
      title: 'How many watts?'
      text: """
  The wattage is how much power the panels generate. The higher the wattage, the more power (and larger dimensions) - typically you'll see 100W, 160W and 175W panels, and most people buy several to get their desired amount
  """
    }
    {
      title: 'Mono vs poly panels'
      text: """
Monocrystalline panels are a little more space-efficient and work a bit better in low-lighting, but are also more expensive. Since you're likely limited on space either to store or mount your panels, Mono panels tend to be better
"""
    }
    {
      title: 'Pure sine vs modified sine inverter'
      text: """
Pure sine produces a power output exactly like in a house. Modified sine is cheaper, but is less efficient and may damage high-end electronics over time. Some electronics won't even work with modified sine inverters
"""
    }
  ]
  videos: [
    # {sourceType: 'youtube', sourceId: '4-OpzH5sBG4', name: 'How many watts to get'}
  ]


products =
  "go-power-weekender-160w":
    name: 'Go Power! Weekender complete kit with 160W (Mono)'
    description: '''
This quality kit has everything you need, including instructions, except for a battery. 160 watts is pretty low, but
it\'s enough to get started. The 1500 watt pure sine inverter is a good size that should
power most things you want to use. It has a 30A transfer switch, so this kit isn't ideal if your RV is 50A.
'''
    itemSlug: 'solar-kit'
    source: 'amazon'
    sourceId: 'B0015398OU'
    decisions: ['160W', 'Mono', 'Pure sine']
    videos: [
      {sourceType: 'youtube', sourceId: 'gdy_j3oJkuc', name: 'Review'}
    ]

  "go-power-weekender-320w":
    name: 'Go Power! Solar elite complete kit with 320W (Mono)'
    description: '''
This kit is similar to the Go Power! 160w kit, but with beefed up components. More wattage, a bigger inverter (that doubles as a smart charger), and a 50A transer switch.
'''
    itemSlug: 'solar-kit'
    source: 'amazon'
    sourceId: 'B0015398PE'
    decisions: ['320W', 'Mono', 'Pure sine']

  "windynation-400w-kit":
    name: 'WindyNation complete 400W kit (Poly)'
    description: '''
This kit is cheap, with a good amount of watts, but all of the parts are the "cheap" variant too. Polycrystalline panels, a modified sine inverter.
'''
    itemSlug: 'solar-kit'
    source: 'amazon'
    sourceId: 'B00HKK5VXY'
    decisions: ['400W', 'Poly', 'Modified sine']
    videos: [
      {sourceType: 'youtube', sourceId: 'p5BmUA5Dnjc', name: 'Installation of similar kit (same brand)'}
    ]
module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
