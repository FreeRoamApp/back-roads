_ = require 'lodash'
fs = require 'fs'

config = require '../../config'

items = fs.readdirSync('./resources/data/items')

items = scyllaTables = _.filter _.flatten _.map items, (itemFile) ->
  {item, products} = require('./items/' + itemFile)
  item

module.exports = items

# replacements:
# {Home} or {home} with van, RV, etc...

###
renogy-100ah-agm-battery https://amzn.com/B075RFXHYK

champion-3400w-dual-fuel-inverter-generator https://amzn.com/B01FAWMMEY

wen-1250w-inverter-generator https://amzn.com/B074H5HGSX

aims-power-2000w-pure-sine-inverter-charger https://amzn.com/B019RHJK70

wzrelb-3000w-pure-sine-inverter https://amzn.com/B0792LW2H7

kinverch-1000w-pure-sine-inverter https://amzn.com/B07KM1BGSC

renogy-100w-portable-solar-panel https://amzn.com/B079JVBVL3

southwire-surge-guard-30a https://amzn.com/B07BNVKS9F

progressive-industries-30a https://amzn.com/B0050EGS5W

---

ruixu-100ah-lithium-battery https://amzn.com/B07PBCDVHZ

###

# TODO: wiring

# TODO: fans, weboost?, different types of levelers, better generator options, better batteries
# mats?, camping chairs, grill, outdoor table, cell plans / booster / hotspot, propane heater, shower head, composting toilet, water (collapsible?) containers, air compressor, laundry bag?

# TODO: different items and products for van / motorhome / 5th wheel / travel trailers
# eventually 30v50 amp

# queryInfo
  # styles: ['van', 'motorhome']
  # amperage: ['30a', '50a'] defaults to all
