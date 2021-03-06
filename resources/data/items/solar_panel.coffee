# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'solar-panel'
  id: '566558e0-ba07-11e8-ac60-37c8d7de3c61'
  name: 'Solar Panel'
  categories: ['boondocking']
  priority: 2
  why: 'Solar panels are the easy, quiet version of powering your RV off-grid. As long as you have sun and a decent setup, you are fully self-sustaining.'
  # what: ''

  filters:
    rigType: ['car', 'tent', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some']

  decisions: [
    {
      title: 'Mounted vs portable'
      text: """
Mounting solar panels on your roof means more upfront work, but less work over time. You can also continue charginging your batteries while driving. With portable panels, you'll have to bring them outside and set them up when you want to charge, but have the advantage that you can put them where they'll get the most sun.
"""
    }
    {
      title: 'How many watts?'
      text: """
The wattage is how much power the panels generate. The higher the wattage, the more power (and larger dimensions) - typically you'll see 100W, 160W and 175W panels, and most people buy several to get their desired amount
"""
    }
    {
      title: 'Mono vs poly'
      text: """
Monocrystalline panels are a little more space-efficient and work a bit better in low-lighting, but are also more expensive. Since you're likely limited on space either to store or mount your panels, Mono panels tend to be better
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: '4-OpzH5sBG4', name: 'How many watts to get'}
    {sourceType: 'youtube', sourceId: 'spdYGUtZVcU', name: 'Mono vs Poly'}
  ]


products =
  "renogy-100w-solar-panel-mono":
    id: '5797eed0-bcb8-11e9-ae14-9ff7b60d89f8'
    name: 'Renogy 100W Solar Panel'
    priority: 2
    filters:
      rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']

    description: '''
Renogy is the most well-known brand of RV solar panels, and these are good panels that are priced well
'''
    itemSlug: 'solar-panel'
    source: 'amazon'
    sourceId: 'B009Z6CW7O'
    reviewersLiked: ['Quality material', 'Priced well']
    reviewersDisliked: ['Sharp edges', 'Small percent of units arrived damaged (glass)']
    decisions: ['Mounted', '100W', 'Mono']

  "newpowa-100w-solar-panel-poly":
    id: '6354ffb0-bcb8-11e9-a4b6-8fcb1ed74bb7'
    name: 'Newpowa 100W Polycrystalline Solar Panel'
    priority: 3
    filters:
      rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']

    description: '''
This is your most budget-friendly panel. They're Polycrystalline, so they're bigger than most panels, but it's a way to save a few bucks
'''
    itemSlug: 'solar-panel'
    source: 'amazon'
    sourceId: 'B00L6LZRXM'
    reviewersLiked: ['Great value', 'Well-built']
    reviewersDisliked: ['Lower than expected power output']
    decisions: ['Mounted', '100W', 'Poly']

  "renogy-100w-portable-solar-panel":
    id: '6367eb70-bcb8-11e9-bcc5-313e87bffb64'
    name: 'Renogy 100W Portable Solar Panel'
    priority: 1
    filters:
      rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']

    description: '''
This has everything you need to get started with solar, if you want a portable panel. 100W isn't a ton, but it's a start, and this includes the charge controller, so you'll be ready to hook up directly to your battery.
'''
    itemSlug: 'solar-panel'
    source: 'amazon'
    sourceId: 'B079JVBVL3'
    reviewersLiked: ['Good value', 'Easy to use']
    reviewersDisliked: ['Poor customer service']
    decisions: ['Portable', '100W', 'Mono']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
