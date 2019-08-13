# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'inverter'
  id: '6b5a2f50-ba07-11e8-bdb7-ffa1efdd209b'
  name: 'Inverter'
  categories: ['boondocking']
  priority: 4
  filters:
    rigType: ['van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some']
  why: """
Inverters transform the 12V power from your batteries to 120V power, which lets you run computers, microwave, a coffee pot, etc... when not plugged into shore power or a generator

Some choose to wire the inverter directly into their 120V system, so all existing plugs work, while others do an easier installation, just hooking it up to the 12V battery and plugging electronics directly into the inverter.
"""
  # what: ''
  decisions: [
    {
      title: 'How many watts?'
      text: """
Inverters can only power so much at one time - this is measured by the wattage. To run a ceiling fan (~100W), Microwave (~1,500W) and TV (~100W) at the same time, your inverter would need to be at least 1,700W.

Usually 2,000W is a good number. If you wanted to run your A/C off of the inverter, you'd need more, you'll probably want to use a generator for A/C since it would drain your batteries very quickly. If you don't need a microwave, coffee pot, blender or hair dryer, you can probably get by with 1,000W
"""
    }
    {
      title: 'Pure sine vs modified sine'
      text: """
Pure sine produces a power output exactly like in a house. Modified sine is cheaper, but is less efficient and may damage high-end electronics over time. Some electronics won't even work with modified sine inverters
"""
    }
    {
      title: 'Inverter vs Inverter Charger'
      text: """
Most RVs have an inverter and a converter. A converter is the opposite of an inverter, it converts 120V power to 12V to charge the batteries. Some inverters are inverter chargers where they fill both roles (inverter and converter). They're also typically more efficent at charging batteries than normal converters.
"""
    }
    {
      title: 'Voltage'
      text: """
In almost all cases, you'll want a 12V inverter. If you need a 24V or 48V one, you'll already know"
"""
    }

  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'mi1gLrlR-Co', name: 'Inverters explained'}
  ]


products =
  "aims-power-2000w-pure-sine-inverter-charger":
    id: '2cf13380-bcb8-11e9-a9bd-54ad0dcf3a5b'
    name: 'AIMS Power 2000W Inverter Charger'
    description: '''
A good-quality inverter charger that will give you pure sine 120V, as well as charge your batteries efficiently
'''
    source: 'amazon'
    sourceId: 'B019RHJK70'
    decisions: ['2000W', 'Pure sine', 'Inverter Charger']
    data:
      countryOfOrigin: 'China'

  "giandel-2000w-modified-sine-inverter":
    id: '3d600ca0-bcb8-11e9-bce6-2719ad19684d'
    name: 'GIANDEL 2000W Power Inverter'
    description: '''
A cheap inverter that will get you 120V power, but it's modified sine, so your electronics might not work properly.
'''
    source: 'amazon'
    sourceId: 'B07MMB23LS'
    decisions: ['2000W', 'Modified sine', 'Inverter']
    data:
      countryOfOrigin: 'China'

  "wzrelb-3000w-pure-sine-inverter":
    id: '3d6ed9b0-bcb8-11e9-aa9c-490162b0aac3'
    name: 'WZRELB 3000W Power Inverter'
    description: '''
If you need to power a bit more than most, this inverter is 3,000W and has good reviews
'''
    source: 'amazon'
    sourceId: 'B0792LW2H7'
    decisions: ['3000W', 'Pure sine', 'Inverter']
    data:
      countryOfOrigin: 'China'

  "kinverch-1000w-pure-sine-inverter":
    id: '3d76a1e0-bcb8-11e9-a271-28b665356d84'
    name: 'Kinverch 1000W Power Inverter'
    description: '''
If you're on a budget, but still want pure sine, this is probably your best option. It's only 1,000W so you may not be able to run a microwave, but it'll power laptops, TVs, etc...
'''
    source: 'amazon'
    sourceId: 'B07KM1BGSC'
    decisions: ['1000W', 'Pure sine', 'Inverter']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
