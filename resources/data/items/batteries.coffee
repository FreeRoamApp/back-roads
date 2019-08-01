# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'batteries'
  id: '6fe55cc0-ba07-11e8-872f-18e7258b765c'
  name: 'Batteries'
  categories: ['boondocking']
  why: "Batteries are what will power all of your electronics. By default they'll power anything 12v (lights, water pump, etc...) and with an inverter, they'll power 120v (laptops, microwave, A/C). The goal with solar and generators is typically just to keep your batteries charged, and the batteries will provide the power."
  what: "You'll most-likely need a 12V deep cycle battery. A standard car battery is different, so be sure it's a deep cycle battery."
#   what: '''With complex products like batteries, it's best to watch a video or two to learn more about which you should buy.
# '''

  decisions: [
    {
      title: 'How many amp hours?'
      text: """
Every electronic you have draws a certain amount of amps. A laptop uses 2-4 amps all the way up to a microwave at closer to 100 amps. Multiply that by how many hours that electronic is drawing power and you have amp hours, which batteries are rated in. You can use [this](https://gpelectric.com/tools/GoPowerCalculator.htm?state=RvDiv) calculator to determine your needs. Most people go with 200-400 amp hours, but you can get by with just 100

Keep in mind that if you're going with lead acid batteries, you should only drain your battery down to 50%, so you'll typically needs to get double the amount of amp hours you think you can use.

Typically you'll buy multiple 100Ah batteries and combine them in parallel to get 200, 300, etc... amp hours
"""
    }
    {
      title: 'Lithium vs AGM vs lead acid'
      text: "Lithium batteries are by far the most expensive, but also much better than lead acid and AGM batteries. They can be discharged more without damaging the batteries, charged quicker, are lighter-weight, have longer lifespans (more cycles), and have several other benefits. Since it can be discharged more, a 100Ah lithium battery is roughly equivalent to two 100Ah lead acid or AGM

AGM is the middle ground - they don't require venting or maintainence and are priced between Lithium and AGM

Lead acid batteries will be cheapest, and they'll definitely work, but they do need to be vented (most RVs have a vented spot for batteries) and typically have some upkeep (checking / adding distilled water every few weeks)"
    }
    {
      title: 'Name brand vs off brand'
      text: "Basically any battery you get is going to come from China. With Lithium batteries, most cells (battery internals) come from China, and with some, they're assembed in China vs others assembled in the US. The \"Name Brand\" will get you a better warranty and support, but will cost more"
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'UfMROVzjVWU', name: 'Lithium vs Lead Acid'}
    {sourceType: 'youtube', sourceId: 'ZJD19RogRtg', name: 'RV batteries explained'}
  ]


products =
  "mighty-max-100ah-battery":
    name: 'Mighty Max 100Ah Lead Acid Battery'
    description: '''
As of this writing, the cheapest 100Ah lead acid battery on Amazon. You can find cheaper at local retailers, since these are expensive to ship (which is reflected in the price), but the reviews for this one are good.
'''
    reviewersLiked: ['Great value', 'Worked as-promised']
    reviewersDisliked: ['Some died around 1-2 years']
    decisions: ['100Ah', 'Lead Acid', 'Off Brand']
    source: 'amazon'
    sourceId: 'B00S2MDZFK'
    data:
      countryOfOrigin: 'China'

  "renogy-100ah-agm-battery":
    name: 'Renogy 100Ah AGM Battery'
    description: '''
A good, budget AGM battery. Not much more than the lead acid, but with less maintenance and no requirement to vent. Renogy is a well-known brand in the RVing space.
'''
    reviewersLiked: ['High quality', 'Good customer service']
    reviewersDisliked: ['Small percentage were dead-on-arrival']
    decisions: ['100Ah', 'AGM', 'Name Brand']
    source: 'amazon'
    sourceId: 'B075RFXHYK'
    data:
      countryOfOrigin: 'China'

  "battle-born-100ah-lithium-battery":
    name: 'Battle Born 100Ah Lithium battery'
    description: '''
These are the cream of the crop batteries, and the price tag reflects it. You'll get good support, a good warranty, and excellent lithium batteries, if you're willing to spend that much.
'''
    source: 'amazon'
    sourceId: 'B06XX197GJ'
    reviewersLiked: ['Charges fast', 'More usable amp hours', 'Reliable', 'Lightweight']
    reviewersDisliked: ['Upfront cost']
    decisions: ['100Ah', 'Lithium', 'Name Brand']
    data:
      countryOfOrigin: 'USA'
    videos: [
      {sourceType: 'youtube', sourceId: 'WVxvBkeY0UY', name: 'Battle Born ($950) vs Ruixu ($750)'}
    ]

  "ruixu-100ah-lithium-battery":
    name: 'Ruixu 100Ah Lithium battery'
    description: '''
The budget option for lithium batteries. Watch the video to learn more about this one - it performs well, but doesn't have a low-temp cutoff, or as good of a warranty
'''
    source: 'amazon'
    sourceId: 'B07PBCDVHZ'
    decisions: ['100Ah', 'Lithium', 'Off Brand']
    videos: [
      {sourceType: 'youtube', sourceId: 'WVxvBkeY0UY', name: 'Battle Born ($950) vs Ruixu ($750)'}
    ]

module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
