# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'chargers'
  id: '151a5a00-bdf0-11e9-afa7-4c5758d29230'
  name: 'Battery Chargers'
  priority: 2
  categories: ['starting-out']
  why: ""
  what: ''

  filters:
    rigType: ['tent', 'car', 'van']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some']

  decisions: [
    {
      title: 'How many mAh?'
      text: "Milliamp-hours (mAh) are a measure of how much storage a battery pack/charger has. The higher the mAh, the better.

A good base point to go off of is that each 4,000 mAh will charge an iPhone X approximately one time from empty to full. Battery packs will typically range from 5,000mAh to 75,000mAh. If you just need to charge a phone or two, 10,000mAh should be fine, but if you want to charge a laptop, you might need up to 75,000mAh.

If you're familiar with Amp-hour storage of other battery types, do note that it's not necessarily a 1:1 comparison since these battery chargers are measured at 5v, whereas others are 12v"
    }
    {
      title: 'USB-only vs Laptop/USB'
      text: "Most battery packs just let you charge through USB ports, but some of the higher-end ones will let you charge your laptop as well"
    }
    {
      title: 'Amp output'
      text: "The Amp output is a measure of how quickly the battery pack will charge your devices. The higher the output, the quicker your device will charge, so long as your device can utilize all of the amps being sent. Phone with fast-charging usually accept up to 3 Amps, while laptops pull up to 5 Amps"
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'ovF4iYkfCiI', name: 'Battery banks explained'}
  ]

products =
  "anker-powercore-20100mah":
    id: 'cbe1b8c0-be11-11e9-b3b7-6bb6f0f77256'
    name: 'Anker PowerCore 20100mAh'
    description: "A good mid-range pack that will charge an iPhone X 5 times. Has 2 USB ports"
    source: 'amazon'
    sourceId: 'B00X5SP0HC'
    decisions: ['20,100mAh', 'USB-only', '4.8A']

  "renogy-72000mah-power-bank":
    id: '90ef8470-be09-11e9-88bf-113e19dfcc72'
    name: 'Renogy 72000mah Power Bank'
    description: "If you want one of the beefiest options you can get to keep your electronics charged, this is it. If you were just charging an iPhone X, you could charge it to full close to 20 times, but this is more for charging laptops. You'll need to make sure you can plug your laptop into this, however, and likely purchase an adapter for it"
    source: 'amazon'
    sourceId: 'B0791WDZTW'
    decisions: ['72,000mAh','Laptop/USB', '13A']
    videos: [
      # {sourceType: 'youtube', sourceId: 'fzry-To2his', name: 'Coleman Fold N Go Review'}
    ]

  "anker-powercore-5000mah":
    id: '9108d8d0-be09-11e9-b0db-c6682a807046'
    name: 'Anker PowerCore 5000mAh'
    description: "An affordable option for charging a single phone for a night or two. Compact and well-made"
    source: 'amazon'
    sourceId: 'B01CU1EC6Y'
    decisions: ['5,000mAh', 'USB', '2A']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
