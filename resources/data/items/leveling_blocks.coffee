# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'leveling-blocks'
  id: '1dd42560-ba07-11e8-8459-7bab72e2aa7d'
  name: 'Levelers'
  categories: ['starting-out']
  why: "Many RV parks and boondocking spots you visit won't be very level. You'll want your RV level not only for comfort reasons, but also to ensure your fridge works properly. Leveling blocks are the easiest way to get your rig level."

  filters:
    rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Wood vs plastic'
      text: """
The cheapest option is to just use some stacked 2x6's to level. The reasons for using plastic are 1) it's not going to rot and 2) they're usually specialized to be easier to use (either with lego-like stacking, or curved levelers)
"""
    }
    {
      title: 'Flat vs curved'
      text: """
Flat leveling blocks look like legos that you stack together and drive over. Curved levelers are a rounded piece of plastic you drive on and insert a chock in the gap it creates.
"""
    }
  ]
  videos: [

  ]


products =
  "lynx-levelers":
    id: '50110d90-bcb8-11e9-a4df-f782fe493654'
    name: 'Lynx Levelers (10 pack)'
    description: "Probably the most popular leveling blocks sold. These are budget-friendly lego-like pieces of plastic that you stack in a pyramid and drive over to get level"
    itemSlug: 'leveling-blocks'
    source: 'amazon'
    sourceId: 'B0028PJ10K'
    reviewersLiked: ['Lightweight', 'Very strong', 'Convenient carrying bag']
    reviewersDisliked: ['Some wished the were wider', 'Not strong enough for a 30,000lb motorhome']
    decisions: ['Plastic', 'Flat']
    videos: [
      {sourceType: 'youtube', sourceId: '2eE0YSkR51Q', name: 'Lynx Levelers'}
    ]
    data:
      countryOfOrigin: 'USA'

  "andersen-levelers":
    id: '5026df80-bcb8-11e9-bcc1-9413ab354a68'
    name: 'Andersen Levelers'
    description: "These are a good bit more expensive than flat plastic blocks, but people tend to prefer them for ease-of-use. Do note that they don't work very well on soft ground"
    itemSlug: 'leveling-blocks'
    source: 'amazon'
    sourceId: 'B001GC2LVM'
    decisions: ['Plastic', 'Curved']
    videos: [
      {sourceType: 'youtube', sourceId: 'sk7teMWhN6c', name: 'Andersen Levelers'}
    ]


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
