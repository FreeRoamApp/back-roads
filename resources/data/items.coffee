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
starting-out:
handheld vacuum
bubble level
first-aid

kitchen category

boondocking:
gas can
propane heater


pet / eco-friendly: https://www.amazon.com/CompostaPoop-Biodegradable-Compostable-Friendly-Dispenser/dp/B07BH31GTM
trash grabber
reusable rv dump gloves B01EAIR384

###

###
blackstone-griddle-grill https://amzn.com/B0195MZHBK
coleman-fold-n-go-grill https://amzn.com/B001RU04XK
weber-q1200-grill https://amzn.com/B00FGEHG6Q
weber-go-anywhere-grill https://amzn.com/B00004RALJ

redcamp-aluminum-folding-table https://amzn.com/B07331DTM6
alps-mountaineering-camp-table https://amzn.com/B000MN8D2M
lifetime-camping-table https://amzn.com/B003YJPC2A

anker-powercore-20100mah https://amzn.com/B00X5SP0HC
renogy-72000mah-power-bank https://amzn.com/B0791WDZTW
anker-powercore-5000mah https://amzn.com/B01CU1EC6Y

portal-steel-folding-chair https://amzn.com/B073PQ6KG2
zero-gravity-lounge-chairs https://amzn.com/B003KK3C52
sportneer-camping-chair https://amzn.com/B01N67GCKW
coleman-camping-quad-chair https://amzn.com/B0033990ZQ

dji-mavic-2-pro https://amzn.com/B07GDC5X74
dji-mavic-air https://amzn.com/B078WQ9SN3
dji-spark https://amzn.com/B071SKF6PS
tello-quadcopter https://amzn.com/B07BDHJJTH

arcshell-two-way-radios https://amzn.com/B072JJFVJG
midland-two-way-radios https://amzn.com/B072JJFVJG
motorola-t100-talkabout-radios https://amzn.com/B01DM7AESK
###

# TODO: wiring

# TODO: fans, weboost?, different types of levelers, better generator options, better batteries
# mats?, camping chairs, cell plans / booster / hotspot, propane heater, shower head, composting toilet, water (collapsible?) containers, air compressor, laundry bag?

# starting out tent camping: tent, sleeping bag, sleeping pad, ice chest, chargers
# outdoor: hammock, mat, chairs,

# tech: drones, action cam, backup cam, weboost, walkie-talkies

# TODO: different items and products for van / motorhome / 5th wheel / travel trailers
# eventually 30v50 amp

# queryInfo
  # styles: ['van', 'motorhome']
  # amperage: ['30a', '50a'] defaults to all
