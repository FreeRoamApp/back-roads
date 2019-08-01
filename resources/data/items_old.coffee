# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: fans, weboost?, different types of levelers, better generator options, better batteries
# mats?, camping chairs, grill, outdoor table, cell plans / booster / hotspot, propane heater, shower head, composting toilet, water (collapsible?) containers, air compressor, laundry bag?

# TODO: different items and products for van / motorhome / 5th wheel / travel trailers
# eventually 30v50 amp

# queryInfo
  # styles: ['van', 'motorhome']
  # amperage: ['30a', '50a'] defaults to all

# loop through all items

# cknex = require '../../services/cknex'
# console.log cknex.getTimeUuid()


# this will translate to campsites too... which will have a lot more than items. need to be efficient.

items =
  # TODO: showerhead. either starting-out or a comfort category?

  'multimeter':
    id: 'fd9b65b0-ba06-11e8-89d7-6990eabd64a2'
    name: 'Multimeter'
    categories: ['maintenance']
    why: 'A multimeter will help you diagnose electrical problems in the RV'
    what: "Most multimeters will let you test AC and DC voltage and resistance. Some will let you test only one of AC or DC current. Even fewer let you check for voltage without contact to the actual wire copper (with clamps),  but it's a nice feature to have."
    videos: [
      {sourceType: 'youtube', sourceId: 'TdUK6RPdIrA', name: 'How to use a multimeter'}
    ]

  'water-filter':
    id: '0334ced0-ba07-11e8-9988-7960460b8db4'
    name: 'Water Filter'
    categories: ['starting-out']
    why: 'Campgrounds don’t always have the cleanest water, so it’s good to filter for both health and taste.'
    what: 'There are three types of water filters. Interior, exterior and container.' # TODO

  'black-tank-treatment':
    id: '15ff4b30-ba07-11e8-9aa7-d26ceb2ea707'
    name: 'Black Tank Treatment'
    categories: ['starting-out', 'maintenance']
    why: "Black tanks are pretty gross... Solids and toilet paper can build up, so you're going to want to use some sort of treatment to break things down and keep things from smelling too bad..."
    what: 'Most people use drop-in packs - you drop one into the toilet after you dump the black tank, and add a few gallons of water - that\'s it! Alternatively you can use a pour-in detergent, which works the same - just in liquid-form.'

  'leveling-blocks':
    id: '1dd42560-ba07-11e8-8459-7bab72e2aa7d'
    name: 'Leveling Blocks'
    categories: ['starting-out']
    why: "Many RV parks and boondocking spots you visit won't be very level. You'll want your RV level not only for comfort reasons, but also to ensure your fridge works properly. Leveling blocks are the easiest way to get your rig level."
    what: 'Most leveling blocks are lego-like stackable pieces of plastic, but curved levelers that also act as chocks are also available.'

  'chocks':
    id: '233603c0-ba07-11e8-b868-7fe74d6cc370'
    name: 'Chocks'
    categories: ['starting-out']
    why: "You don’t want your RV rolling off, do you? ;) Chocks will prevent that."
    what: "There are two types of chocks: wedge and X-style. Most people who use the X-style use them in combination with the wedge style. The advantage of X-style is added stability (less back and forth rocking), whereas wedge chocks are generally much cheaper."

  'fresh-water-hose':
    id: '2a517900-ba07-11e8-bb5e-ba6f45de3c43'
    name: 'Fresh Water Hose'
    categories: ['starting-out']
    why: "You need a hose to hook up the city water to your RV - a specific type of hose that doesn't have lead or BPAs, since you'll be drinking from it."
    what: "The main difference between fresh water hoses is going to be the length and durability / kink-prevention... but for the most part they're all pretty similar."

  'water-pressure-regulator':
    id: '3bd9d870-ba07-11e8-ae17-7448845529f2'
    name: 'Water Pressure Regulator'
    categories: ['starting-out']
    why: "Some city water hookups will have pressure that's high enough to damage your RV's pipes. A regulator will reduce water pressure to an acceptable amount (40-50 PSI)"
    what: "The only differences you'll see between regulators is some have gauges, and some let you adjust the PSI you want"

  'sewer-hose':
    id: '43e61650-ba07-11e8-9d0b-142dc46cb0ec'
    name: 'Sewer Hose'
    categories: ['starting-out']
    why: "You'll need a sewer hose to get the black and gray water out of your RV and into the RV park's septic or sewer system"
    what: "The main difference between the hoses will be durability and length. We recommend at least 20 feet, since you never know how far a hookup will be from your rig."

  'sewer-hose-support':
    id: '51cb3750-ba07-11e8-823c-724ed99823a5'
    name: 'Sewer Hose Support'
    categories: ['starting-out']
    why: "These let gravity do its job with the fluids going through your sewer hose. It also keeps your hose off the ground, to help prevent damage to the hose. Some RV parks even require them."
    what: "There isn't much variety here - just varying lengths to match your sewer hose."


  # 'generator-adapter':
  #   name: 'Generator Adapter'
  #   categories: ['boondocking']
  #   why: "" # 30A to 15A
  #   what: ""


###
some sort of introduction message / tooltip?

Whether you're an experienced boondocker or just starting out, we want to help
you learn about and find the most helpful products!

basically no one uses search....

could do "save to backpack", or a customized approach where we learn about user
(rv type, experience, goals), and recommend items (and they can say what they already have)

could add reviews now, but doubt anyone would leave any

items: batteries, solar panel, generator, charge-controller, black-tank-treatment,
       inverter, chocks, multimeter, leveling blocks ,sealant, fresh-water-host, ...

      batteries 10x
###


  # camping chairs


  # grill


  # outdoor table


  # cell plans / booster / hotspot

  # propane heater

  # shower head

  # composting toilet

  # water (collapsible?) containers

  # air compressor

  # laundry bag?



module.exports = _.map items, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
