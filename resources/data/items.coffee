# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

items =
  'surge-protector':
    name: 'Surge Protector'
    categories: ['starting-out']
    why: 'Electricity is not something to mess around with - one bad electrical hookup and you could fry your internal RV systems. Surge protectors will let you know when a hookup is going to cause problems, and even prevent issues with power surges and outages.'
    what: 'First off, you’ll need the correct amperage for your RV: 30amp or 50amp. You’ll probably want something that’s weather-proof.'

  'sealant':
    name: 'Sealant'
    categories: ['maintenance']
    why: 'RVs are notorious for leaking and causing water damage - often to the extent that fixing it costs more than the RV is worth. Making sure everything is sealed up properly will save you from that headache.'
    what: '''The are 3 common sealants to use. Sealant Tape (eg. Eternabond) is commonly used to seal vents and other openings on roofs. Self-leveling sealant can be used instead of tape on the roof, or complementary to tape for seams with non-straight edges. Non-sag sealant is for seams on the sides of your

          You’ll need to make sure that the sealant you’re using works with your roof-type. We also recommend against silicone sealants since they’re a pain to inevitably fix (you need to fully remove any silicone sealant before applying more).'''

  'water-filter':
    name: 'Water Filter'
    categories: ['starting-out']
    why: 'Campgrounds don’t always have the cleanest water, so it’s good to filter for both health and taste.'
    what: 'There are three types of water filters. Interior, exterior and container.' # TODO

  'black-tank-treatment':
    name: 'Black Tank Treatment'
    categories: ['starting-out', 'maintenance']
    why: "Black tanks are pretty gross... Solids and toilet paper can build up, so you're going to want to use some sort of treatment to break things down and keep things from smelling too bad..."
    what: 'Most people use drop-in packs - you drop one into the toilet after you dump the black tank, and add a few gallons of water - that\'s it! Alternatively you can use a pour-in detergent, which works the same - just in liquid-form.'

  'leveling-blocks':
    name: 'Leveling Blocks'
    categories: ['starting-out']
    why: "Many RV parks and boondocking spots you visit won't be very level. You'll want your RV level not only for comfort reasons, but also to ensure your fridge works properly. Leveling blocks are the easiest way to get your rig level."
    what: 'Most leveling blocks are lego-like stackable pieces of plastic, but curved levelers that also act as chocks are also available.'

  'chocks':
    name: 'Chocks'
    categories: ['starting-out']
    why: "You don’t want your RV rolling off, do you? ;) Chocks will prevent that."
    what: "There are two types of chocks: wedge and X-style. Most people who use the X-style use them in combination with the wedge style. The advantage of X-style is added stability (less back and forth rocking), whereas wedge chocks are generally much cheaper."

  'fresh-water-hose':
    name: 'Fresh Water Hose'
    categories: ['starting-out']
    why: "You need a hose to hook up the city water to your RV - a specific type of hose that doesn't have lead or BPAs, since you'll be drinking from it."
    what: "The main difference between fresh water hoses is going to be the length and durability / kink-prevention... but for the most part they're all pretty similar."

  'water-pressure-regulator':
    name: 'Water Pressure Regulator'
    categories: ['starting-out']
    why: "Some city water hookups will have pressure that's high enough to damage your RV's pipes. A regulator will reduce water pressure to an acceptable amount (40-50 PSI)"
    what: "The only differences you'll see between regulators is some have gauges, and some let you adjust the PSI you want"

  'sewer-hose':
    name: 'Sewer Hose'
    categories: ['starting-out']
    why: "You'll need a sewer hose to get the black and gray water out of your RV and into the RV park's septic or sewer system"
    what: "The main difference between the hoses will be durability and length. We recommend at least 20 feet, since you never know how far a hookup will be from your rig."

  'sewer-hose-support':
    name: 'Sewer Hose Support'
    categories: ['starting-out']
    why: "These let gravity do its job with the fluids going through your sewer hose. It also keeps your hose off the ground, to help prevent damage to the hose. Some RV parks even require them."
    what: "There isn't much variety here - just varying lengths to match your sewer hose."

module.exports = _.map items, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
