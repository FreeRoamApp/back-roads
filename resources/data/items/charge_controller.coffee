# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'charge-controller'
  id: '64a8ed90-ba07-11e8-b8a5-42d3bcf1c1ac'
  name: 'Charge Controller'
  categories: ['boondocking']
  why: "Charge controllers regulate the voltage and current from the panels to the batteries to prevent overcharging."

  # what: ''
  decisions: [
    {
      title: 'PWM vs MPPT'
      text: """
MPPT is ~30% more efficient in charging batteries and can work with voltages other than 12V. Of course, it also costs more. If you're working more than 400W of solar, you'll likely need an MPPT controller

In most cases, you'll want an MPPT over PWM
"""
    }
    {
      title: 'Amp rating'
      text: """
You'll need a charge controller that can handle however many Amps of current you're sending it from the solar panels.

If you have 600W running **in parallel** on 18V panels, you are at 33A and thus need a 40A charge controller. (600W / 18V = 33.33A)

If you have 600W where two panels are in series those series are wired in parallel, you are running at 36V and 17A, so a 20A or 30A charge controller is enough (600W / 36V = 16.66A)

It's also good to "size up", in case you add more solar panels in the future (all things considered, the panels themselves are some of the cheapest parts)
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'kF_cVEYxj3E', name: 'Charge controller buyer guide'}
    {sourceType: 'youtube', sourceId: 'PB6zojol9o0', name: 'PWM vs MPPT'}
  ]

products =
  "epever-30a-mppt-solar-charge-controller":
    name: 'EPEVER 30A MPPT Charge Controller'
    description: '''
'''
    itemSlug: 'charge-controller'
    source: 'amazon'
    sourceId: 'B01GMUPH0O'
    decisions: ['MPPT', '30A']
    data:
      countryOfOrigin: 'China'

  "renogy-wanderer-30a-pwm-charge-controller":
    name: 'Renogy Wanderer 30A PWM Charge Controller'
    description: '''

'''
    itemSlug: 'charge-controller'
    source: 'amazon'
    sourceId: 'B00BCTLIHC'
    reviewersLiked: ['Simplicity', 'Good for small installs']
    reviewersDisliked: ['Not as efficient as MPPT']
    decisions: ['PWM', '30A']
    data:
      countryOfOrigin: 'China'



module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
