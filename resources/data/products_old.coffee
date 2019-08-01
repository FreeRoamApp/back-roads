# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO:
# parameters: [{name: 'name', value: 'value'}]
# eg: parameters: [{name: 'watts', value: 100}, {name: 'type', value: 'monocrystalline'}]
# eg2: parameters: [{name: 'type', value: 'roof-caulk'}]
# eg3: water pressure regulator parameters: [{name: 'hasGauge', value: true}] / [{name: 'hasGauge', value: false}]

products =

  "uni-t-clamp-multimeter":
    name: 'Uni-T AC/DC Current Mini Clamp Capacitance Tester'
    description: '''
- 100A AC and DC current measurement with 1mA resolution, V.F.C function for measuring signal at varia
- 600V ac and dc voltage measurement, resistance, diode, continuity and capacitance functions
- Non-contact voltage detection with led indication, display backlight
'''
    itemSlug: 'multimeter'
    source: 'amazon'
    sourceId: 'B00O1Q2HOQ'
    reviewersLiked: []
    reviewersDisliked: []
    data:
      countryOfOrigin: 'China'

  "astroai-multimeter":
    name: 'AstroAI Digital Multimeter with Ohm Volt Amp and Diode Voltage Tester'
    description: 'Accurately measures voltage, DC current, resistance, diode, continuity and more'
    itemSlug: 'multimeter'
    source: 'amazon'
    sourceId: 'B01ISAMUA6'
    reviewersLiked: []
    reviewersDisliked: []
    data:
      countryOfOrigin: 'China'

  "camco-tastepure-with-hose":
    name: 'Camco TastePURE with Flexible Host'
    description: "This filter is hooked up to your fresh water hose outside. Removes bacteria and carbon, reduces chlorine, odor, contaminants, sediment, and particulates for better taste and healthier drinking water. Each filter lasts about 3 months."
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B0006IX87S'
    reviewersLiked: ['Easy to install', 'Doesn\'t noticeably reduce water pressure', 'Stops sediment from entering water lines and tanks']
    reviewersDisliked: ['Some (not many) experienced leakage at filter inlet', 'Water didn\'t taste good enough to some']
    data:
      countryOfOrigin: 'Unknown'

  "brita-pitcher-5-cup":
    name: 'Small Brita Pitcher (5 cup)'
    description: "Space-efficient water filter pitcher. Height 9.8\" Width 4.45\", Depth 9.37\". Filters last ~2 months. Reduces chlorine taste and odor, copper, mercury, and cadmium impurities. Good for keeping water cold and tasty, small enough to not take up too much RV fridge space."
    itemSlug: 'water-filter'
    source: 'amazon'
    sourceId: 'B015SY3W7K'
    data:
      countryOfOrigin: 'Unknown'

  "bio-pak-digester":
    name: 'Walex Bio-Pak Holding Tank Deodorizer and Waste Digester'
    description: "Deodorizes and breaks down waste and paper. Pre-packaged portion control - no measuring or pouring"
    itemSlug: 'black-tank-treatment'
    source: 'amazon'
    sourceId: 'B00157TGXY'
    reviewersLiked: ['Super easy to use', 'Reduces odors', 'Breaks down solids and toilet paper well']
    reviewersDisliked: ['Poop still smells bad']
    data:
      countryOfOrigin: 'Unknown'

  "lynx-levelers":
    name: 'Lynx Levelers (10 pack)'
    description: """
Modular designed levelers not only configure to fit any leveling function, but they also withstand tremendous weight

To use: simply set them into a pyramid shape to the desired height that the RV needs to be raised and drive onto the stack

The levelers can also be used as a support base for other stabilizing equipment"""
    itemSlug: 'leveling-blocks'
    source: 'amazon'
    sourceId: 'B0028PJ10K'
    reviewersLiked: ['Lightweight', 'Very strong', 'Convenient carrying bag']
    reviewersDisliked: ['Some wished the were wider', 'Not strong enough for a 30,000lb motorhome']
    data:
      countryOfOrigin: 'USA'

  "camco-plastic-wheel-chocks":
    name: 'Camco Plastic Wheel Chocks'
    description: "Durable hard plastic with UV inhibitors. For use with tires up to 26\" in diameter"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B00K1C1WC2'
    reviewersLiked: ['Cheap', 'Sturdy', 'Lightweight']
    reviewersDisliked: ['Crushed under steep grades and heavy weight', 'Not as good of traction on concrete']
    data:
      countryOfOrigin: 'Unknown'

  "x-chock-wheel-stabilizer":
    name: 'X-Chock Wheel Stabilizer'
    description: "Provides added stabilization and prevents tire shifts by applying opposing force to tandem tire applications"
    itemSlug: 'chocks'
    source: 'amazon'
    sourceId: 'B002XLHUQG'
    reviewersLiked: ['Much less movement when people are walking inside', 'High quality']
    reviewersDisliked: ['Still need normal chocks in addition to these', 'Somewhat heavy']
    data:
      countryOfOrigin: 'USA'

  "camco-25-drinking-water-hose":
    name: 'Camco 25\' TastePURE Drinking Water Hose'
    description: '''
- Reinforced for maximum kink resistance
- 25' long x 5/8\"ID
- Hose is made of PVC and is BPA free'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B004ME11FS'
    reviewersLiked: ['Cheap', 'For the most part, it doesn\'t kink']
    reviewersDisliked: ['Not fully kink-proof', 'Leaked for a small percentage of users']
    data:
      countryOfOrigin: 'Unknown'

  "apex-teknor-neverkink-50":
    name: 'Apek Teknor NeverKink 50\' Drinking Water Hose'
    description: '''
- Rigid sleeve prevents kinking at the faucet
- Drinking Water Safe - Manufactured with FDA sanctioned materials
- 50' long, 5/8\"ID'''
    itemSlug: 'fresh-water-hose'
    source: 'amazon'
    sourceId: 'B0001MII88'
    reviewersLiked: ['Durable', 'For the most part, it doesn\'t kink']
    reviewersDisliked: ['Not fully kink-proof', 'Leaked for a small percentage of users']
    data:
      countryOfOrigin: 'Unknown'

  "thetford-20-premium-sewer-hose":
    name: 'Thetford 20\' Premium RV Sewer Hose Kit'
    description: "Easy to mount on RV waste outlet with the Extended Grip universal bayonet mount. TPE hose prevents leaks and is uncrushable - bounces back in shape even after being run over by a car"
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B01MRRSPOM'
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-super-kit-sewer-hose":
    name: 'Camco 20\' Super Kit RV Sewer Hose Kit'
    description: "SUPER kit includes two 10' 18mil super heavy-duty HTS vinyl sewer hoses with pre-attached swivel fittings"
    itemSlug: 'sewer-hose'
    source: 'amazon'
    sourceId: 'B06Y1F55J7'
    data:
      countryOfOrigin: 'Unknown'

  "camco-20-sewer-hose-support":
    name: 'Camco 20\' Sewer Hose Support'
    description: "The 20ft Sidewinder RV Sewer Hose Support by Camco lifts and cradles your sewer hose while in connection from your RV to the dump station. It keeps your sewer hose off the ground and prevents potential damage or punctures to your RV or camper sewer hose by safely nesting it in heavy duty plastic."
    itemSlug: 'sewer-hose-support'
    source: 'amazon'
    sourceId: 'B000BUU5WW'
    data:
      countryOfOrigin: 'Unknown'

  "camco-inline-water-pressure-regulator":
    name: 'Camco Inline Water Pressure Regulator'
    description: """
- Helps protect RV plumbing and hoses from high-pressure city water.
- Attaches easily with 3/4" garden hose threads.
- Durable brass construction that is drinking water safe.
- Reduces water pressure to a safe and consistent 40-50 lbs of pressure"""
    itemSlug: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B003BZD08U'
    data:
      countryOfOrigin: 'Unknown'

  "renator-adjustable-water-pressure-regulator":
    name: 'Renator Adjustable Water Pressure Regulator'
    description: """Adjustable up to 160 PSI with gauge to monitor current pressure."""
    itemSlug: 'water-pressure-regulator'
    source: 'amazon'
    sourceId: 'B01N7JZTYX'
    data:
      countryOfOrigin: 'Unknown'


module.exports = _.map products, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
