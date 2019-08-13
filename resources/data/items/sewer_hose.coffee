# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'sewer-hose'
  id: '43e61650-ba07-11e8-9d0b-142dc46cb0ec'
  name: 'Sewer Hose'
  categories: ['starting-out']
  why: "You'll need a sewer hose to get the black and gray water out of your {home} and into the RV park or dump station's septic or sewer system"

  filters:
    rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'How long?'
      text: """
The sewer hose needs to be able to reach the hookup at the RV park or dump station. Typically 20' is a good length, and often times the hoses will come as two separate 10' sections, so if you're close when at a dump station, you only need to get one out
"""
    }
    {
      title: 'Crush-resistant / heavy-duty vs not'
      text: """
You probably won't be running over your sewer hose with a car, or otherwise "crushing" the sewer hose, but they typically are more durable (and more expensive)

The cheaper sewer hoses tend to get brittle and crack over time
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'ixynZc0BUNQ', name: 'How to dump black and gray tanks'}
  ]


products =
  "thetford-20-premium-sewer-hose":
    id: '502fe030-bcb8-11e9-b3be-a6adf1f68454'
    name: 'Thetford 20\' Premium RV Sewer Hose Kit'
    description: "A mid-tier sewer hose. Not the best quality, not the worst."
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B01MRRSPOM'
    decisions: ['20\'', 'Crush-resistant']
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-super-kit-sewer-hose":
    id: '57804820-bcb8-11e9-905f-7766d63fe959'
    name: 'Camco 20\' Super Kit RV Sewer Hose Kit'
    description: "The budget option. It works, but tends to get brittle and crack over time"
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B06Y1F55J7'
    decisions: ['20\'']
    data:
      countryOfOrigin: 'Unknown'

  "lippert-waste-master-20-sewer-hose":
    id: '578fb170-bcb8-11e9-b46f-ce8cd90aaa47'
    name: 'Lipper Waste Master 20\' Sewer Hose'
    description: "The Rolls-Royce of sewer hoses... but holy cow it's expensive. If you want the highest-quality, durable sewer hose, this is it."
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B010X65OHE'
    decisions: ['20\'', 'Heavy-duty']
    videos: [
      {sourceType: 'youtube', sourceId: 'FcU7FGyz4HY', name: 'Lippert Waste Master Review'}
    ]



module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
