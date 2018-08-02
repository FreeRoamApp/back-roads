# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

products =
  "camco-heavy-duty-dogbone-rv-surge-protector":
    name: 'Camco Heavy Duty Dogbone Surge Protector'
    description: "The Camco 30M/30F AMP Circuit Analyzer helps protect your electrical equipment from improperly wired electrical boxes by visually indicating faults before you connect your RV's Power Cord to the electrical box. The 125V Dogbone includes surge protection up to 2100 joules. It is weatherproof, with durable power grip handles for safe and easy plugging and unplugging. NEMA TT-30 Plug and Receptacle."
    itemId: 'surge-protector'
    source: 'amazon'
    sourceId: 'B00WED0XBC'
    data:
      countryOfOrigin: 'Unknown'
    # TODO: bullets that are uniform across all item's products (eg max voltage, ...)

  "trc-surge-guard-34830":
    name: 'TRC Surge Guard with LCD Display'
    description: "The 30 Amp Surge Guard portable with LCD display offers more than twice the Joules of power surge protection than the previous model. Continuously monitors for voltage and amp draw and reverse polarity (miswired pedestal, elevated ground voltage). Compact and easy to use, they plug in between the power pedestal and the line cord to provide protection. Designed for all travel trailers, 5th wheels and motorhomes with 30 Amp service."
    itemId: 'surge-protector'
    source: 'amazon'
    sourceId: 'B00T36Q7R2'
    data:
      countryOfOrigin: 'Honduras'

  "dicor-self-leveling":
    name: 'Dicor Self-Leveling Lap Sealant'
    description: "Helps creates a watertight seal along the roof's edges, around air vents, vent pipes, air conditioners, and screw heads. Compatible with EPDM sheeting, it offers excellent adhesion to aluminum, mortar, wood, vinyl, galvanized metal, and concrete. It improves the ability to continuously seal and remain flexible. Color matched, it is UV stabilized to prevent deterioration and discoloration and will not stain or discolor any material to which it is applied. 10.3 ounce tubes, White."
    itemId: 'sealant'
    source: 'amazon'
    sourceId: 'B000BRF7QE'
    data:
      countryOfOrigin: 'Unknown'


module.exports = _.map products, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
