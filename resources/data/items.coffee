# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

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
  'surge-protector':
    id: 'e7664710-ba06-11e8-9337-58da70b4ae7a'
    name: 'Surge Protector'
    categories: ['starting-out']
    why: 'Electricity is not something to mess around with - one bad electrical hookup and you could fry your internal RV systems. Surge protectors will let you know when a hookup is going to cause problems, and even prevent issues with power surges and outages.'
    what: 'First off, you’ll need the correct amperage for your RV: 30amp or 50amp. You’ll probably want something that’s weather-proof.'
    videos: [
      {sourceType: 'youtube', sourceId: 'LrbBJjWNl2I'}
    ]

  'sealant':
    id: 'f5ac73d0-ba06-11e8-8465-51c4cbccc446'
    name: 'Sealant'
    categories: ['maintenance']
    why: 'RVs are notorious for leaking and causing water damage - often to the extent that fixing it costs more than the RV is worth. Making sure everything is sealed up properly will save you from that headache.'
    what: '''The are 3 common sealants to use. Sealant Tape (eg. Eternabond) is commonly used to seal vents and other openings on roofs. Self-leveling sealant can be used instead of tape on the roof, or complementary to tape for seams with non-straight edges. Non-sag sealant is for seams on the sides of your

          You’ll need to make sure that the sealant you’re using works with your roof-type. We also recommend against silicone sealants since they’re a pain to inevitably fix (you need to fully remove any silicone sealant before applying more).'''
    videos: [
      {sourceType: 'youtube', sourceId: 'spdYGUtZVcU'}
    ]

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

  'solar-panel':
    id: '566558e0-ba07-11e8-ac60-37c8d7de3c61'
    name: 'Solar Panel'
    categories: ['boondocking']
    why: 'Solar panels are the easy, quiet version of powering your RV off-grid. As long as you have sun and a decent setup, you are fully self-sustaining.'
    what: '''You'll come across several variations:

- **Mounted vs portable**: Most RVers mount solar panels to the roof, but you can also get portable panels that you set out front
- **Wattage**: The wattage is how much power the panels generate. The higher the wattage, the more power (and larger dimensions) - typically you'll see 100W, 160W and 175W.
- **Mono vs Poly**: Mono is a little more space-efficient and works bit better in low-lighting, but are also a little more expensive. We recommend Mono
- **Physical size**: Panel size typically grows proportionally with wattage, but you'll want to maximize the empty space you have on your roof

See the videos below for more info on these differences
'''
    videos: [
      {sourceType: 'youtube', sourceId: '4-OpzH5sBG4', name: 'How many watts to get'}
      {sourceType: 'youtube', sourceId: 'spdYGUtZVcU', name: 'Mono vs Poly'}
    ]
# mono vs poly TCq0K3DlFdc

  'charge-controller':
    id: '64a8ed90-ba07-11e8-b8a5-42d3bcf1c1ac'
    name: 'Charge Controller'
    categories: ['boondocking']
    why: "Charge controllers regulate the voltage and current from the panels to the batteries to prevent overcharging."
    what: "The main difference in charge controllers is PWM vs MPPT and the gist between those two is MPPT is they're about 30% more efficient in charging you batteries."

  'inverter':
    id: '6b5a2f50-ba07-11e8-bdb7-ffa1efdd209b'
    name: 'Inverter'
    categories: ['boondocking']
    why: "Inverters transform the 12V power from your batteries to 120V power, which you need for electronics, microwave, A/C etc... Many RVs come with inverters now, so be sure to check if you have one already."
    what: '''The main differences you'll see between inverters are:

- **Pure sine** vs Modified sine: Pure sine produces a power output exactly like in a house. Modified sine is cheaper, but is less efficient and may damage high-end electronics over time.
- **Wattage**: Inverters can only power so much at one time - this is measured by the wattage. To run a ceiling fan (~100W), Microwave (~1,500W) and TV (~100W) at the same time, your inverter would need to be at least 1,700W. Usually 2000+ is recommended.
'''
    videos: [
      {sourceType: 'youtube', sourceId: 'mi1gLrlR-Co', name: 'Inverters explained'}
    ]

  'batteries':
    id: '6fe55cc0-ba07-11e8-872f-18e7258b765c'
    name: 'Batteries'
    categories: ['boondocking']
    why: "Batteries are what will power all of your electronics. The goal with solar and generators is typically just to keep your batteries charged"
    what: '''There are a few things to take into consideration:

- **Amp Hours**: The more amp hours (Ah), the longer your batteries will power your stuff. Most people start with ~200Ah.
- **Lithium vs lead acid**: Lithium batteries are far more expensive, but also far better than lead acid batteries. They can be discharged more without damaging the batteries, are smaller, have longer lifespans (more cycles), and have several other benefits.

With complex products like batteries, it's best to watch a video or two to learn more about which you should buy.
'''
    videos: [
      {sourceType: 'youtube', sourceId: 'UfMROVzjVWU', name: 'Lithium vs Lead Acid'}
      {sourceType: 'youtube', sourceId: 'ZJD19RogRtg', name: 'RV batteries explained'}
    ]

  'generator':
    id: '73de0e30-ba07-11e8-9fde-687163ee8e09'
    name: 'Generator'
    categories: ['boondocking']
    why: "Solar is great, but if you want to run A/C, or have string of cloudy days, it's good to have a generator. You can even use just a generator without solar. A generator will charge your batteries and give you power off-grid."
    what: '''The two main things to pay attention to are the wattage, and whether it's an inverter or convential generator.

- **Wattage**: An inverter can only power so many things at once, and this is limited by the wattage. An RV A/C takes ~3,000W to start and 1,500 watts while running, but most other electronics will take 1,500 or less. ~2,000W is generally good for anything but A/C, but you'll need 3,000+ if you want A/C.
- **Inverter vs Conventional**: Inverter generators are *much* quieter, smaller and lighter, but also more expensive and top out at a lower wattage.
'''
    videos: [
      {sourceType: 'youtube', sourceId: '-sWJzM_Snmc', name: 'RV generators explained'}
    ]

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
