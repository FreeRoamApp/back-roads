# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

item =
  key: 'batteries'
  id: '6fe55cc0-ba07-11e8-872f-18e7258b765c'
  name: 'Batteries'
  categories: ['boondocking']
  why: "Batteries are what will power all of your electronics. The goal with solar and generators is typically just to keep your batteries charged"
  what: '''There are a few things to take into consideration:

- **Amp Hours**: The more amp hours (Ah), the longer your batteries will power your stuff. Most people start with ~200Ah.
- **Lithium vs lead acid**: Lithium batteries are far more expensive, but also far better than lead acid batteries. They can be discharged more without damaging the batteries, are smaller, have longer lifespans (more cycles), and have several other benefits.

With complex products like batteries, it's best to watch a video or two to learn more about which you should buy.
'''

  decisions: [
    {
      title: 'How many amp hours?'
      text: ""
    }
    {
      title: 'Lithium or lead acid?'
      text: ""
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
'''
    itemSlug: 'batteries'
    source: 'amazon'
    sourceId: 'B00S2MDZFK'
    data:
      countryOfOrigin: 'China'

  "battle-born-100ah-lithium-battery":
    name: 'Battle Born 100Ah Lithium battery'
    description: '''
'''
    itemSlug: 'batteries'
    source: 'amazon'
    sourceId: 'B06XX197GJ'
    reviewersLiked: ['Batteries charge fast', 'More usable amp hours', 'Reliable', 'Lightweight']
    reviewersDisliked: ['Upfront cost']
    data:
      countryOfOrigin: 'USA'


module.exports = _.map items, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
