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
