# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

module.exports = {items: [], products: []} # FIXME
return






item =
  slug: 'sealant'
  id: 'f5ac73d0-ba06-11e8-8465-51c4cbccc446'
  name: 'Sealant'
  categories: ['maintenance']
  why: 'RVs are notorious for leaking and causing water damage - often to the extent that fixing it costs more than the RV is worth. Making sure everything is sealed up properly will save you from that headache.'
  what: '''The are 3 common sealants to use. Sealant Tape (eg. Eternabond) is commonly used to seal vents and other openings on roofs. Self-leveling sealant can be used instead of tape on the roof, or complementary to tape for seams with non-straight edges. Non-sag sealant is for seams on the sides of your

        You’ll need to make sure that the sealant you’re using works with your roof-type. We also recommend against silicone sealants since they’re a pain to inevitably fix (you need to fully remove any silicone sealant before applying more).'''

  decisions: [
    {
      title: 'Self-leveling vs non-sag vs tape'
      text: ""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'spdYGUtZVcU'}
  ]

products =
  "dicor-self-leveling":
    name: 'Dicor Self-Leveling Lap Sealant'
    description: "Helps creates a watertight seal along the roof's edges, around air vents, vent pipes, air conditioners, and screw heads. Compatible with EPDM sheeting, it offers excellent adhesion to aluminum, mortar, wood, vinyl, galvanized metal, and concrete. It improves the ability to continuously seal and remain flexible. Color matched, it is UV stabilized to prevent deterioration and discoloration and will not stain or discolor any material to which it is applied. 10.3 ounce tubes, White."
    source: 'amazon'
    sourceId: 'B000BRF7QE'
    reviewersLiked: ['Easy to apply to horizontal surfaces', 'Long-lasting']
    reviewersDisliked: ['Some had issues with product taking a long time to dry']
    decisions: ['Self-leveling']
    data:
      countryOfOrigin: 'Unknown'

  "dicor-non-sag":
    name: 'Dicor Non-Sag Lap Sealant'
    description: "Non sag formula can be used on vertical or horizontal surfaces. Good for windows and other seams on the sides of your RV"
    source: 'amazon'
    sourceId: 'B004RCSR1G'
    reviewersLiked: ['Long-lasting', 'Much better than silicone - silicon is very hard to maintain long-term', 'Adheres well']
    reviewersDisliked: ['Dries fast, making it a little harder to work with compared to typical caulk']
    decisions: ['Non-sag']
    data:
      countryOfOrigin: 'Unknown'

  "eternabond-roofseal-tape":
    name: 'Eternabond RoofSeal Tape'
    description: "Sealant tape for your RV roof - easy to install and extremely durable. Simple installation only requires some surface preparation before use."
    source: 'amazon'
    sourceId: 'B002RSIK4G'
    reviewersLiked: ['Super sticky (in a good way)', 'Long lasting (hence the name)', 'Easy to install', 'Looks good on white roofs']
    reviewersDisliked: ['Not great around curves / rounded areas']
    decisions: ['Tape']
    data:
      countryOfOrigin: 'Unknown'


module.exports = {item, products: _.map products, (product, slug) -> _.defaults {itemSlug: item.slug, slug}, product}
# coffeelint: enable=max_line_length,cyclomatic_complexity
