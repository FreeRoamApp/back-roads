# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: our take?
# What reviewers say: summary positive and negative


products =
  "camco-heavy-duty-dogbone-rv-surge-protector":
    name: 'Camco Heavy Duty Dogbone Surge Protector, 30A'
    description: "The Camco 30M/30F AMP Circuit Analyzer helps protect your electrical equipment from improperly wired electrical boxes by visually indicating faults before you connect your RV's Power Cord to the electrical box. The 125V Dogbone includes surge protection up to 2100 joules. It is weatherproof, with durable power grip handles for safe and easy plugging and unplugging. NEMA TT-30 Plug and Receptacle."
    itemId: 'surge-protector'
    source: 'amazon'
    sourceId: 'B00WED0XBC'
    reviewersLiked: ['Easy to read indicator lights', 'Peace of mind', 'Priced well']
    reviewersDisliked: ['Despite being weather resistant, some had issues with water getting inside', 'Easy for someone to steal', 'Bulky and heavy']
    data:
      countryOfOrigin: 'Unknown'
    # TODO: bullets that are uniform across all item's products (eg max voltage, ...)

  "trc-surge-guard-34830":
    name: 'TRC Surge Guard with LCD Display, 30A'
    description: "The 30 Amp Surge Guard portable with LCD display offers more than twice the Joules of power surge protection than the previous model. Continuously monitors for voltage and amp draw and reverse polarity (miswired pedestal, elevated ground voltage). Compact and easy to use, they plug in between the power pedestal and the line cord to provide protection. Designed for all travel trailers, 5th wheels and motorhomes with 30 Amp service."
    itemId: 'surge-protector'
    source: 'amazon'
    sourceId: 'B00T36Q7R2'
    reviewersLiked: ['Screen with voltage and amperage draw readouts', 'Peace of mind']
    reviewersDisliked: ['Bulky and heavy']
    data:
      countryOfOrigin: 'Honduras'

  "dicor-self-leveling":
    name: 'Dicor Self-Leveling Lap Sealant'
    description: "Helps creates a watertight seal along the roof's edges, around air vents, vent pipes, air conditioners, and screw heads. Compatible with EPDM sheeting, it offers excellent adhesion to aluminum, mortar, wood, vinyl, galvanized metal, and concrete. It improves the ability to continuously seal and remain flexible. Color matched, it is UV stabilized to prevent deterioration and discoloration and will not stain or discolor any material to which it is applied. 10.3 ounce tubes, White."
    itemId: 'sealant'
    source: 'amazon'
    sourceId: 'B000BRF7QE'
    reviewersLiked: ['Easy to apply to horizontal surfaces', 'Long-lasting']
    reviewersDisliked: ['Some had issues with product taking a long time to dry']
    data:
      countryOfOrigin: 'Unknown'

  "dicor-non-sag":
    name: 'Dicor Non-Sag Lap Sealant'
    description: "Non sag formula can be used on vertical or horizontal surfaces. Good for windows and other seams on the sides of your RV"
    itemId: 'sealant'
    source: 'amazon'
    sourceId: 'B004RCSR1G'
    reviewersLiked: ['Long-lasting', 'Much better than silicone - silicon is very hard to maintain long-term', 'Adheres well']
    reviewersDisliked: ['Dries fast, making it a little harder to work with compared to typical caulk']
    data:
      countryOfOrigin: 'Unknown'

  "eternabond-roofseal-tape":
    name: 'Eternabond RoofSeal Tape'
    description: "Sealant tape for your RV roof - easy to install and extremely durable. Simple installation only requires some surface preparation before use."
    itemId: 'sealant'
    source: 'amazon'
    sourceId: 'B002RSIK4G'
    reviewersLiked: ['Super sticky (in a good way)', 'Long lasting (hence the name)', 'Easy to install', 'Looks good on white roofs']
    reviewersDisliked: ['Not great around curves / rounded areas']
    data:
      countryOfOrigin: 'Unknown'

  "camco-tastepure-with-hose":
    name: 'Camco TastePURE with Flexible Host'
    description: "This filter is hooked up to your fresh water hose outside. Removes bacteria and carbon, reduces chlorine, odor, contaminants, sediment, and particulates for better taste and healthier drinking water. Each filter lasts about 3 months."
    itemId: 'water-filter'
    source: 'amazon'
    sourceId: 'B0006IX87S'
    reviewersLiked: ['Easy to install', 'Doesn\'t noticeably reduce water pressure', 'Stops sediment from entering water lines and tanks']
    reviewersDisliked: ['Some (not many) experienced leakage at filter inlet', 'Water didn\'t taste good enough to some']
    data:
      countryOfOrigin: 'Unknown'

  "brita-pitcher-5-cup":
    name: 'Small Brita Pitcher (5 cup)'
    description: "Space-efficient water filter pitcher. Height 9.8\" Width 4.45\", Depth 9.37\". Filters last ~2 months. Reduces chlorine taste and odor, copper, mercury, and cadmium impurities. Good for keeping water cold and tasty, small enough to not take up too much RV fridge space."
    itemId: 'water-filter'
    source: 'amazon'
    sourceId: 'B015SY3W7K'
    data:
      countryOfOrigin: 'Unknown'

  "bio-pak-digester":
    name: 'Walex Bio-Pak Holding Tank Deodorizer and Waste Digester'
    description: "Deodorizes and breaks down waste and paper. Pre-packaged portion control - no measuring or pouring"
    itemId: 'black-tank-treatment'
    source: 'amazon'
    sourceId: 'B00157TGXY'
    data:
      countryOfOrigin: 'Unknown'

  "lynx-levelers":
    name: 'Lynx Levelers (10 pack)'
    description: """
Modular designed levelers not only configure to fit any leveling function, but they also withstand tremendous weight

To use: simply set them into a pyramid shape to the desired height that the RV needs to be raised and drive onto the stack

The levelers can also be used as a support base for other stabilizing equipment"""
    itemId: 'leveling-blocks'
    source: 'amazon'
    sourceId: 'B0028PJ10K'
    data:
      countryOfOrigin: 'USA'

  "camco-plastic-wheel-chocks":
    name: 'Camco Plastic Wheel Chocks'
    description: "Durable hard plastic with UV inhibitors. For use with tires up to 26\" in diameter"
    itemId: 'chocks'
    source: 'amazon'
    sourceId: 'B00K1C1WC2'
    data:
      countryOfOrigin: 'Unknown'

  "x-chock-wheel-stabilizer":
    name: 'X-Chock Wheel Stabilizer'
    description: "Provides added stabilization and prevents tire shifts by applying opposing force to tandem tire applications"
    itemId: 'chocks'
    source: 'amazon'
    sourceId: 'B002XLHUQG'
    data:
      countryOfOrigin: 'USA'

  "camco-25-drinking-water-hose":
    name: 'Camco 25\' TastePURE Drinking Water Hose'
    description: "Reinforced for maximum kink resistance. 25' long x 5/8\"ID. Hose is made of PVC and is BPA free"
    itemId: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B004ME11FS'
    data:
      countryOfOrigin: 'Unknown'

  "apex-teknor-neverkink-50":
    name: 'Apek Teknor NeverKink 50\' Drinking Water Hose'
    description: "Rigid sleeve prevents kinking at the faucet. Drinking Water Safe - Manufactured with FDA sanctioned materials. 50' long, 5/8\"ID"
    itemId: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B0001MII88'
    data:
      countryOfOrigin: 'Unknown'

  "thetford-20-premium-sewer-hose":
    name: 'Thetford 20\' Premium RV Sewer Hose Kit'
    description: "Easy to mount on RV waste outlet with the Extended Grip universal bayonet mount. TPE hose prevents leaks and is uncrushable - bounces back in shape even after being run over by a car"
    itemId: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B01MRRSPOM'
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-super-kit-sewer-hose":
    name: 'Camco 20\' Super Kit RV Sewer Hose Kit'
    description: "SUPER kit includes two 10' 18mil super heavy-duty HTS vinyl sewer hoses with pre-attached swivel fittings"
    itemId: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B06Y1F55J7'
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-sewer-hose-support":
    name: 'Camco 20\' Sewer Hose Support'
    description: "The 20ft Sidewinder RV Sewer Hose Support by Camco lifts and cradles your sewer hose while in connection from your RV to the dump station. It keeps your sewer hose off the ground and prevents potential damage or punctures to your RV or camper sewer hose by safely nesting it in heavy duty plastic."
    itemId: 'sewer-hose-support'
    source: 'amazon'
    sourceId: 'B000BUU5WW'
    data:
      countryOfOrigin: 'Unknown'

  "camco-inline-water-pressure-regulator":
    name: 'Camco Inline Water Pressure Regulator'
    description: """Helps protect RV plumbing and hoses from high-pressure city water.
Attaches easily with 3/4" garden hose threads.
Durable brass construction that is drinking water safe.
Reduces water pressure to a safe and consistent 40-50 lbs of pressure"""
    itemId: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B003BZD08U'
    data:
      countryOfOrigin: 'Unknown'

  "renator-adjustable-water-pressure-regulator":
    name: 'Renator Adjustable Water Pressure Regulator '
    description: """Adjustable up to 160 PSI with gauge to monitor current pressure."""
    itemId: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B01N7JZTYX'
    data:
      countryOfOrigin: 'Unknown'

module.exports = _.map products, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
