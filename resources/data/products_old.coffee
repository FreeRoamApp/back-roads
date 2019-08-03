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

  "camco-20-sewer-hose-support":
    name: 'Camco 20\' Sewer Hose Support'
    description: "The 20ft Sidewinder RV Sewer Hose Support by Camco lifts and cradles your sewer hose while in connection from your RV to the dump station. It keeps your sewer hose off the ground and prevents potential damage or punctures to your RV or camper sewer hose by safely nesting it in heavy duty plastic."
    itemSlug: 'sewer-hose-support'
    source: 'amazon'
    sourceId: 'B000BUU5WW'
    data:
      countryOfOrigin: 'Unknown'


module.exports = _.map products, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
