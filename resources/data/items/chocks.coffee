# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'chocks'
  id: '233603c0-ba07-11e8-b868-7fe74d6cc370'
  name: 'Chocks'
  categories: ['starting-out']
  why: "You don’t want your RV rolling off, do you? ;) Chocks will prevent that. They can also get you more stability in your {home}, preventing back and forth rocking"

  filters:
    rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Plastic vs rubber'
      text: """
Plastic chocks are much cheaper and lighter-weight, but not nearly as durable as rubber. If you have a very heavy fifth wheel, motorhome, etc... It's probably a good idea to use rubber
"""
    }
    {
      title: 'Wedge vs X-style'
      text: """
Most people who use the X-style use them in combination with the wedge style. The advantage of X-style is added stability (less back and forth rocking), whereas wedge chocks are generally much cheaper
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: '0QmK2B-el80', name: 'Chock-type stability comparison'}
  ]


products =
  "camco-plastic-wheel-chocks":
    id: '052843c0-bcb8-11e9-8055-da2510309121'
    name: 'Camco Plastic Wheel Chocks'
    description: "Your basic, cheap plastic wheel chocks"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B00K1C1WC2'
    reviewersLiked: ['Cheap', 'Sturdy', 'Lightweight']
    reviewersDisliked: ['Crushed under steep grades and heavy weight', 'Not as good of traction on concrete']
    decisions: ['Plastic', 'Wedge']
    data:
      countryOfOrigin: 'Unknown'

  "x-chock-wheel-stabilizer":
    id: '052eac60-bcb8-11e9-9f45-6a38f66380fd'
    name: 'X-Chock Wheel Stabilizer'
    filters:
      rigType: ['travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some', 'all']

    description: "Provides added stabilization and prevents tire shifts by applying opposing force to tandem tire applications"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B002XLHUQG'
    reviewersLiked: ['Much less movement when people are walking inside', 'High quality']
    reviewersDisliked: ['Still need normal chocks in addition to these', 'Somewhat heavy']
    decisions: ['Metal', 'X-style']
    data:
      countryOfOrigin: 'USA'

  "maxxhaul-rubber-wheel-chocks":
    id: '0c4391f0-bcb8-11e9-b364-4da5b30af823'
    name: 'MaxxHaul Rubber Wheel Chocks'
    description: "Durable rubber wheel chocks - they're solid rubber and heavy-duty. Main drawback is they smell pretty bad at first ;)"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B01CGU14T2'
    decisions: ['Rubber', 'Wedge']
    data:
      countryOfOrigin: 'Unknown'
    videos: [
      {sourceType: 'youtube', sourceId: 'ifTC1T9t_f0', name: 'X-Chocks review'}
    ]



module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
