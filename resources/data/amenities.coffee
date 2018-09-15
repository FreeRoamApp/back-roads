# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: 'view satellite' link
# TODO: distanceTo: calculate from other amenities in database? or manually input
# just AZ for now (fall/winter)

# dump, laundry, water, gas, diesel, propane, groceries

amenities =
  # bombo's pond
  'death-valley-inn-rv-park-dump-site':
    name: 'Death Valley Inn & RV Park'
    location: [36.904182, -116.755623]
    amenities: ['water', 'dump']
    prices:
      water: 5
      dump: 5
    details: 'Pay $5 at the inn, then dump at site A2 next to the park host'
  'family-dollar-beatty':
    name: 'Family Dollar Beatty'
    location: [36.906287, -116.757011]
    amenities: ['groceries']
  'space-station-rv-park':
    name: 'Space Station RV Park'
    location: [36.906287, -116.757011]
    amenities: ['groceries', 'propane', 'laundry']

  # scaddan wash
  'rv-pit-stop-quartzite':
    name: 'RV Pit Stop'
    location: [33.673578, -114.216787]
    amenities: ['propane', 'water', 'dump']
    prices:
      dump: 10
      water: 4
  'dollar-general-quartzite':
    name: 'Dollar General Quartzite'
    location: [33.663178, -114.231280]
    amenities: ['groceries']

  # indian-bread-rocks-blm
  'shell-bowie'
    name: 'Shell Bowie'
    location: [32.319150, -109.452341]
    amenities: ['water', 'gas', 'diesel']
    prices:
      water: 0
  'safeway-wilcox'
    name: 'Safeway Wilcox'
    location: [32.263165, -109.842326]
    amenities: ['groceries']
  'mountain-view-rv-park'
    amenities: ['propane', 'dump', 'gas', 'diesel']

  # snyder-hill-blm
  'safeway-tucson-1'
    name: 'Safeway Tucson'
    location: [32.135133, -111.030016]
    amenities: ['groceries']
  'merrigans-arizona-roadrunner'
    name: 'Merrigan\'s Arizona Roadrunner'
    location: [32.285443, -110.994579]
    amenities: ['water', 'dump']
  'uhaul-tucson-1'
    name: 'U-Haul of Southwest'
    location: [32.178424, -110.969300]
    amenities: ['propane']

  # saddle-mountain-blm

  # darby-well-road
  # craggy-wash-blm


module.exports = _.map amenities, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
