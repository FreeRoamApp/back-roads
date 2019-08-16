# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'camping-chairs'
  id: 'f3b1a820-bee7-11e9-b635-aba87de01abe'
  name: 'Camping chairs'
  priority: 3
  categories: ['outdoors', 'starting-out']
  why: "You're probably going to be outdoors a lot, and you're going to need somewhere to sit :)"
  what: ''

  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Style'
      text: "There are a few different styles of chairs:

Director's chair: These chairs don't have much back support, but they're incredibly easy to setup, and they store well if you have an area for flat items. These are probably better if you care about posture too

Zero gravity lounge: This type of chair is built to be the most comfortable, akin to a recliner, but at a cost of taking up more space and being a little pricier.

Compact: These are great if you don't have a lot of space. They're popular with backpackers because they're lightweight and break down to a small size. The drawback is they take a little longer to setup and break down.

Traditional: This is your standard camping chair. Budget-friendly and fairly compact
"
    }
    {
      title: 'Side table vs none'
      text: "A side table for your chair can be nice if you like to keep things like snacks, a book, etc... within arm's reach"
    }
    {
      title: 'Weight capacity'
      text: "You obviously don't want your chair to break on you :)"
    }
  ]
  videos: [
    # {sourceType: 'youtube', sourceId: 'Kbp4LiOjXbI', name: 'Connecting grill to RV propane tank'}
  ]

products =
  "portal-steel-folding-chair":
    id: '5cbe9ac0-beee-11e9-b904-cf3bea8c5624'
    name: 'Portal Steel Folding Chair'
    description: "A popular, affordable director's chair, with a side table"
    source: 'amazon'
    sourceId: 'B073PQ6KG2'
    decisions: ['Directors', 'Side table', '225lbs']

  "zero-gravity-lounge-chairs":
    id: '5ce18c10-beee-11e9-acfb-23bf43cd6d3f'
    name: 'Zero Gravity Lounge Chairs'
    description: "A set of two lounge chairs. Great comfort, not as great for storing"
    source: 'amazon'
    sourceId: 'B003KK3C52'
    decisions: ['Zero-gravity', '250lbs']
    videos: [
      # {sourceType: 'youtube', sourceId: 'fzry-To2his', name: 'Coleman Fold N Go Review'}
    ]

  "sportneer-camping-chairs":
    id: '5cecafa0-beee-11e9-8d68-333d5245d33f'
    name: 'Sportneer Camping Chairs'
    description: "A set of two lightweight, portable chairs. They're made of aluminum, and break down to a small size"
    source: 'amazon'
    sourceId: 'B01N67GCKW'
    decisions: ['Compact', '350lbs']

  "coleman-camping-quad-chair":
    id: '8a771800-bef0-11e9-9ec3-e0bf3b7215c9'
    name: 'Coleman Camping Quad Chair'
    description: "Your basic camping chair, the budget-friendly option :) Well-made, and a relatively high weight limit"
    source: 'amazon'
    sourceId: 'B0033990ZQ'
    decisions: ['Traditional', '325lbs']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
