# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'water-filter'
  id: '0334ced0-ba07-11e8-9988-7960460b8db4'
  name: 'Water Filter'
  categories: ['starting-out']
  why: 'Campgrounds don’t always have the cleanest water, so it’s good to filter for both health and taste.'

  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  # what: ''
  decisions: [
    {
      title: 'Exterior vs under-sink vs container'
      text: """
Exterior water filters are the most-common - you attach it directly to your hose

Under-sink water filters attach to your cold water line somewhere inside the RV, typically by the sink. These are a bit more involved to install, but easiest in the long-run.

Container water filters are just a pitcher that filters the water - you may have used one of these in your home
"""
    }
  ]
  videos: [
  ]


products =
  "camco-tastepure-with-hose":
    id: '728194d0-bcb8-11e9-bf49-4f65e205bd8e'
    name: 'Camco TastePURE'

    filters:
      rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some', 'all']

    description: "Hooks up to your fresh water hose outside, each filter lasts about 3 months."
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B0006IX87S'
    reviewersLiked: ['Easy to install', 'Doesn\'t noticeably reduce water pressure', 'Stops sediment from entering water lines and tanks']
    reviewersDisliked: ['Some (not many) experienced leakage at filter inlet', 'Water didn\'t taste good enough to some']
    decisions: ['External']

  "brita-pitcher-5-cup":
    id: '7d0932f0-bcb8-11e9-881f-465398a6a71e'
    name: 'Small Brita Pitcher (5 cup)'

    filters:
      rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some', 'all']

    description: "You've probably heard of this one before :) Your standard Brita pitcher. Filters last 2 months"
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B015SY3W7K'
    decisions: ['Container']

  "filtrete-water-filtration-system":
    id: '7d180000-bcb8-11e9-b3e4-aa1d30b44d1a'
    name: 'Filtrete Water Filtration System'

    filters:
      rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some', 'all']

    description: "A budget-friendly under-sink filter. Hooks up directly to your cold water line under sink - uses compression fittings to connect, so you'll have to do a bit of (easy) plumbing. Filters last 6 months"
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B001DVW0PI'
    decisions: ['Under-sink']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
