# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'propane-heater'
  id: '2bc31a40-e4b9-11e9-b73b-418fa546908a'
  name: 'Propane Heater'
  priority: 2
  categories: ['boondocking']
  why: "You might already have a heater, but a portable propane heater is going to be the most efficient. It uses less propane, and no battery draw to operate."
  what: "Some of these heaters use small 1 lb propane tanks, but you can get a hose to hook it up directly to your larger propane tank if you have one. Be sure to keep a window or two cracked to let in oxygen and reduce condensation."

  filters:
    rigType: ['car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some']

  decisions: [
    {
      title: 'How many BTUs?'
      text: "BTUs are a little complicated, but all you need to know is the more BTUs, the more capable the heater is of heating a larger room. 3,000 BTU is good for 100 sq ft and 8,000 BTU for 230 sq ft"
    }
    {
      title: 'High vs low pressure propane'
      text: "Mr. Buddy heaters require higher-pressure propane into the unit if you're using a hose, and they regulate the pressure down at the unit. Olympian Waves use low pressure propane. The difference is mostly just you use a different hose, but for the high pressure variants, there is more pressure on the hose. Both types are safe, but Olympian Waves tend to be a little safer."
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'Dx3-h8EjfjI', name: 'Heaters compared'}
  ]

products =
  "mr-heater-buddy":
    id: '7d549a50-e4b9-11e9-a425-007ac8eebf5e'
    name: 'Mr. Heater Buddy'
    description: "A good quality, affordable propane heater for mid-size spaces"
    source: 'amazon'
    sourceId: 'B002G51BZU'
    decisions: ['9,000 BTU', 'High pressure']
    filters:
      rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']


  "mr-heater-big-buddy":
    id: '7d6dc7a0-e4b9-11e9-9bae-f02f1fc860ce'
    name: 'Mr. Heater Big Buddy'
    description: "Largest version of the Buddy heaters. This one also has a fan you can turn on to circulate the warm air."
    source: 'amazon'
    sourceId: 'B01DD6C4TC'
    decisions: ['18,000', 'High pressure']
    filters:
      rigType: ['motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']


  "mr-heater-little-buddy":
    id: 'b81d18d0-e4bc-11e9-b9bd-d2168906a042'
    name: 'Mr. Heater Little Buddy'
    description: "The smallest, most portable propane heater you can get. Good for small spaces"
    source: 'amazon'
    sourceId: 'B001CFRF7I'
    decisions: ['3,800 BTU', 'High pressure']
    filters:
      rigType: ['tent', 'car', 'van']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']


  "camco-olympian-wave-3":
    id: 'b848e3c0-e4bc-11e9-897f-b35bb9070d26'
    name: 'Olympian Wave 3'
    description: "Smallest of the Olympian Wave heaters. These heaters are higher quality and a bit safer than the Buddy heaters, but more expensive."
    source: 'amazon'
    sourceId: 'B000BUV1RK'
    decisions: ['3,000 BTU', 'Low pressure']
    filters:
      rigType: ['car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']


  "camco-olympian-wave-6":
    id: 'b855dc10-e4bc-11e9-99b2-f3b3ee3a812c'
    name: 'Olympian Wave 6'
    description: "Mid-sized Olympian Wave heater. These heaters are higher quality and a bit safer than the Buddy heaters, but more expensive."
    source: 'amazon'
    sourceId: 'B000BV01CK'
    decisions: ['6,000 BTU', 'Low pressure']
    filters:
      rigType: ['car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']


  "camco-olympian-wave-8":
    id: '459782e0-e4bd-11e9-85ed-e5911a7f59f6'
    name: 'Olympian Wave 8'
    description: "Largest of the Olympian Wave heaters. These heaters are higher quality and a bit safer than the Buddy heaters, but more expensive."
    source: 'amazon'
    sourceId: 'B000EDQR8M'
    decisions: ['8,000 BTU', 'Low pressure']
    filters:
      rigType: ['motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']



module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
