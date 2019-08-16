# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'black-tank-treatment'
  id: '15ff4b30-ba07-11e8-9aa7-d26ceb2ea707'
  name: 'Black Tank Treatment'
  categories: ['starting-out', 'maintenance']
  why: "Black tanks are pretty gross... Solids and toilet paper can build up, so you're going to want to use some sort of treatment to break things down and keep things from smelling too bad..."
  what: 'Most people use drop-in packs - you drop one into the toilet after you dump the black tank, and add a few gallons of water - that\'s it! Alternatively you can use a pour-in detergent, which works the same - just in liquid-form.'

  filters:
    rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  # what: ''
  decisions: [
    {
      title: 'Tablet / drop-in pod vs powder vs liquid'
      text: """
All forms of black tank treatment are basically the same, it's just a matter of cost and ease-of use, much like laundry detergent.

Pods are easiest, followed by powder, then liquid. The cost is usually the inverse: liquid is cheapest, then powder, then pods.
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: '903XEB17kEM', name: 'Black tank treatments compared'}
  ]


products =
  "bio-pak-digester":
    id: 'e2849e90-bcb7-11e9-87b9-fb962b4c9811'
    name: 'Bio-Pak Black Tank Deodorizer and Waste Digester'
    description: "Easy to use pods that deodorize and break down waste and paper."
    itemSlug: 'black-tank-treatment'
    source: 'amazon'
    sourceId: 'B00157TGXY'
    reviewersLiked: ['Super easy to use', 'Reduces odors', 'Breaks down solids and toilet paper well']
    reviewersDisliked: ['Poop still smells bad']
    decisions: ['Drop-in pod']

  "happy-campers-organic-black-tank-treatment":
    id: 'e28ab910-bcb7-11e9-bcf0-5b92fb6b035e'
    name: 'Happy Campers Black Tank Treatment'
    description: "A popular powder treatment that deodorizes and liquifies waste and toilet paper"
    itemSlug: 'black-tank-treatment'
    source: 'amazon'
    sourceId: 'B005XEFADU'
    decisions: ['Powder']
    videos: [
      {sourceType: 'youtube', sourceId: '2eE0YSkR51Q', name: 'Happy Campers Review'}
    ]

  "camco-orange-rv-black-tank-treatment":
    id: 'e9cd3e50-bcb7-11e9-9575-8e02b1a38e4f'
    name: 'Camco Orange-Scented Black Tank Treatment'
    description: "The budget option: 64 treatments for a low price"
    itemSlug: 'black-tank-treatment'
    source: 'amazon'
    sourceId: 'B00NFIOLL8'
    decisions: ['Liquid']



module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
