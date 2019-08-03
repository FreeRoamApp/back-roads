# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'fresh-water-hose'
  id: '2a517900-ba07-11e8-bb5e-ba6f45de3c43'
  name: 'Fresh Water Hose'
  categories: ['starting-out']
  why: "You need a hose to hook up the city water to your RV - a specific type of hose that doesn't have lead or BPAs, since you'll be drinking from it."
  decisions: [
    {
      title: 'How long?'
      text: """
You obviously want your hose to be long enough to reach from the spigot to your {home}. 25' is typically long enough.

If you're boondocking, a longer hose can be a convenience if the fresh water spigot is relatively far from the dump station, but you can get by with a short one (you'll just sometimes have to move to get closer after dumping)
"""
    }
    {
      title: 'Heated vs unheated'
      text: """
If you're camping somewhere that gets below freezing and want to stay hooked up to water, you might want a heated hose. This will prevent the water in the hose from freezing and bursting the hose. Heated hoses plug into a 120V receptacle and keep the water inside warm enough that it won't freeze. They are however much more expensive
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'pToXzNWr7DA', name: 'Heated water hoses'}
    {sourceType: 'youtube', sourceId: 'uR9uMhQSvOA', name: 'How to connect water at an RV site'}
  ]


products =
  "camco-25-drinking-water-hose":
    name: 'Camco 25\' TastePURE Drinking Water Hose'
    description: '''
This is the most budget-friendly hose and comes in a variety of lengths
'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B004ME11FS'
    reviewersLiked: ['Cheap', 'For the most part, it doesn\'t kink']
    reviewersDisliked: ['Not fully kink-proof', 'Leaked for a small percentage of users']
    decisions: ['25\'', 'Unheated']

  "apex-teknor-neverkink-50":
    name: 'Apex Teknor NeverKink 50\' Drinking Water Hose'
    description: '''
A bit better quality than the Camco hose, but also more expensive. Comes in 25' and 50' lengths
'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B0001MII88'
    reviewersLiked: ['Durable', 'For the most part, it doesn\'t kink']
    reviewersDisliked: ['Not fully kink-proof', 'Leaked for a small percentage of users']
    decisions: ['50\'', 'Unheated']
    videos: [
      {sourceType: 'youtube', sourceId: 'JBS8u_UhiVc', name: 'Apex NeverKink review'}
    ]

  "valterra-heated-fresh-water-hose-25":
    name: 'Valterra 25\' Heated Fresh Water Hose'
    description: '''
Expensive, but for a reason: this will get you fresh water in freezing temperatures. Comes in 15', 25', and 50'
'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B00ON793UE'
    decisions: ['25\'', 'Heated']
    videos: [
      {sourceType: 'youtube', sourceId: 'pToXzNWr7DA', name: 'Valterra heated hose review'}
    ]



module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
