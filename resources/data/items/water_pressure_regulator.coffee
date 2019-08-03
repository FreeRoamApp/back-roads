# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'water-pressure-regulator'
  id: '3bd9d870-ba07-11e8-ae17-7448845529f2'
  name: 'Water Pressure Regulator'
  categories: ['starting-out']
  why: "Some city water hookups will have pressure that's high enough to damage your RV's pipes. A regulator will reduce water pressure to an acceptable amount (40-50 PSI)"

  decisions: [
    {
      title: 'Adjustable vs fixed'
      text: """
Some regulators will let you set the water pressure (PSI) you want. So you can go a little higher than the 40 PSI that fixed regulators have (if your pipes can handle it), or lower if you want to conserve water.
"""
    }
    {
      title: 'Gauge vs no-gauge'
      text: """
A gauge on a regulator can tell you want the current water pressure is. It's not really necessary, just nice to be able to verify, if your pressure seems low.
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'zTiT_VwXkR0', name: 'Intro to water pressure regulators'}
  ]


products =

  "camco-inline-water-pressure-regulator":
    name: 'Camco Inline Water Pressure Regulator'
    description: """
A barebones, budget-friendly water regulator. It'll do the job of protecting your pipes from high pressure, reducing pressure to 40-50 PSI
"""
    itemSlug: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B003BZD08U'
    decisions: ['Fixed', 'No-gauge']
    data:
      countryOfOrigin: 'Unknown'

  "renator-adjustable-water-pressure-regulator":
    name: 'Renator Adjustable Water Pressure Regulator'
    description: """
You can adjust this to whatever water pressure is best for you, and use the gauge to see what the pressure is. Those features make it the most expensive on this list
"""
    itemSlug: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B01N7JZTYX'
    decisions: ['Adjustable', 'Gauge']
    data:
      countryOfOrigin: 'Unknown'




module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
