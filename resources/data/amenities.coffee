# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: 'view satellite' link
# TODO: distanceTo: calculate from other amenities in database? or manually input
# just AZ for now (fall/winter)

cknex = require '../../services/cknex'
console.log cknex.getTimeUuid()

# dump, laundry, water, gas, propane, groceries

amenities =
  # bombo's pond
  'death-valley-inn-rv-park-dump-site':
    name: 'Death Valley Inn & RV Park'
    id: '532fb3e0-ba08-11e8-b313-6066b1415760'
    location: [36.904182, -116.755623]
    amenities: ['water', 'dump']
    prices:
      water: 5
      dump: 5
    details: 'Pay $5 at the inn, then dump at site A2 next to the park host'
  'family-dollar-beatty':
    name: 'Family Dollar Beatty'
    id: '6f4556c0-ba08-11e8-8e9b-28aeb310dbdf'
    location: [36.906287, -116.757011]
    amenities: ['groceries']
  'space-station-rv-park':
    name: 'Space Station RV Park'
    id: '78dd8bd0-ba08-11e8-9e07-5a437c0c22d3'
    location: [36.911603, -116.756312]
    amenities: ['groceries', 'propane', 'laundry']

  # scaddan wash
  'rv-pit-stop-quartzite':
    name: 'RV Pit Stop'
    id: '73bb7590-ba08-11e8-bd7c-42a66ae93b40'
    location: [33.673578, -114.216787]
    amenities: ['propane', 'water', 'dump']
    prices:
      dump: 10
      water: 4
  'dollar-general-quartzite':
    name: 'Dollar General Quartzite'
    id: '86a07ed0-ba08-11e8-8077-5eceb6f5e734'
    location: [33.663178, -114.231280]
    amenities: ['groceries']

  # indian-bread-rocks-blm
  'shell-bowie':
    name: 'Shell Bowie'
    id: 'a69b7230-ba08-11e8-812d-0d6978c699bb'
    location: [32.319150, -109.452341]
    amenities: ['water', 'gas']
    prices:
      water: 0
  'safeway-wilcox':
    name: 'Safeway Wilcox'
    id: 'ab51ce50-ba08-11e8-93c0-85218541d519'
    location: [32.263165, -109.842326]
    amenities: ['groceries', 'trash']
  'mountain-view-rv-park':
    name: 'Mountain View RV Park'
    id: 'b4c42be0-ba08-11e8-a513-190d0cfe807e'
    location: [32.329750, -109.502643]
    amenities: ['propane', 'dump', 'gas']

  # snyder-hill-blm
  'safeway-tucson-1':
    name: 'Safeway Tucson'
    id: 'b9b63170-ba08-11e8-a594-5e57e192584c'
    location: [32.135133, -111.030016]
    amenities: ['groceries', 'trash']
  'merrigans-arizona-roadrunner':
    name: 'Merrigan\'s Arizona Roadrunner'
    id: 'bde00500-ba08-11e8-9733-3f73ddcf007d'
    location: [32.285443, -110.994579]
    amenities: ['water', 'dump']
  'uhaul-tucson-1':
    name: 'U-Haul of Southwest'
    id: 'c3694180-ba08-11e8-be05-c10ea8da5cd7'
    location: [32.178424, -110.969300]
    amenities: ['propane']

  # saddle-mountain-blm
  'the-cove-rv-resort': # not actually that close to saddle mountain
    name: 'The Cove RV Resort'
    id: '95b8f610-ba10-11e8-b74e-b3b3d803526a'
    location: [33.603618, -114.534739]
    amenities: ['dump', 'water', 'propane']
    prices:
      dump: 10
      water: 10

  'stage-stop-rv-park':
    name: 'Stage Stop RV Park'
    id: '73eae900-ba13-11e8-b054-14347a6e97d8'
    location: [33.422525, -112.868989]
    amenities: ['dump']

  'shell-saddle-mountain':
    name: 'Shell Saddle Mountain'
    id: '191b9370-ba14-11e8-a59b-1d0bb47d14e9'
    location: [33.494224, -112.937499]
    amenities: ['water']

  'walmart-buckeye':
    name: 'Walmart Buckeye'
    id: '1e5e9f30-ba14-11e8-9c41-dfd9b90c36bf'
    location: [33.436908, -112.560312]
    amenities: ['groceries', 'trash']

  'leaf-verde-rv-park':
    name: 'Leaf Verde RV Park'
    id: 'abbeca80-ba14-11e8-9ed8-3a688a9de77c'
    location: [33.431962, -112.574006]
    amenities: ['dump', 'propane']
    prices:
      dump: 15
  # darby-well-road
  'belly-acres-rv-park':
    name: 'Belly Acres RV Park'
    id: '1a9664e0-ba1a-11e8-a15f-6cc36cc035f8'
    location: [32.394032, -112.871314]
    amenities: ['dump', 'water']
    prices:
      dump: 7
      water: 5

  'family-dollar-ajo':
    name: 'Family Dollar Ajo'
    id: '6557a980-ba1a-11e8-8930-d59ba73fecef'
    location: [32.376560, -112.873419]
    amenities: ['groceries']

  'shell-ajo':
    name: 'Shell Ajo'
    id: 'c66ffa60-ba1f-11e8-9d1e-e2d3dce10855'
    location: [32.375106, -112.872631]
    amenities: ['propane', 'gas']

  # craggy-wash-blm
  'crazy-horse-rv-campgrounds':
    name: 'Crazy Horse RV Campgrounds'
    id: '2efde0b0-ba20-11e8-b16e-c2a3917c7e23'
    location: [34.469368, -114.357193]
    amenities: ['dump', 'water']
    prices:
      dump: 5
      water: 5

  'walmart-lake-havasu-city':
    name: 'Walmart Lake Havasu City'
    id: 'd2fce8f0-ba20-11e8-80dc-138403e59b76'
    location: [34.571657, -114.368076]
    amenities: ['groceries', 'trash']

  'amerigas-lake-havasu-city':
    name: 'Amerigas Lake Havasu City'
    id: '336bf3c0-ba21-11e8-8850-c6abdef98230'
    location: [34.506282, -114.348301]
    amenities: ['propane']

  # american-girl-mine-blm
  'rest-area-winterhaven':
    name: 'Rest Area Winterhaven'
    id: '1829df30-babe-11e8-814c-0d78c67a5dac'
    location: [32.737364, -114.890338]
    amenities: ['water', 'trash']

  'chevron-sidewinder':
    name: 'Chevron Sidewinder'
    id: 'a316fcc0-bac0-11e8-9211-2d6d362feb2a'
    location: [32.745387, -114.755294]
    amenities: ['dump', 'trash']
    prices:
      dump: 15

  'walmart-yuma':
    name: 'Walmart Yuma'
    id: 'b120e3d0-bac0-11e8-b438-d431db42b9c5'
    location: [32.712408, -114.652506]
    amenities: ['groceries', 'trash']

  'amerigas-yuma':
    name: 'AmeriGas Yuma'
    id: 'e6c0c3c0-bac0-11e8-863a-466d77a49d19'
    location: [32.698859, -114.595986]
    amenities: ['propane']

  # blair-valley
  'julian-market-and-deli':
    name: 'Julian Market and Deli'
    id: '7e030f80-baef-11e8-a0c9-f49babd8bfc8'
    location: [33.078835, -116.602362]
    amenities: ['groceries']

  'stagecoach-trails-rv-resort':
    name: 'Stagecoach Trails RV Resort'
    id: '9ec86250-baf0-11e8-8c3a-ede2199eaa48'
    location: [33.060269, -116.424864]
    amenities: ['dump', 'water']
    prices:
      dump: 20

  'ramco-julian':
    name: 'Ramco Julian'
    id: '53df2de0-baf1-11e8-97a1-242defa7932b'
    location: [33.076734, -116.600245]
    amenities: ['propane', 'gas']
    # accessibility:
    #   gas: 2
    #   diesel: 2

  # joshua-tree-blm-south
  'chevron-chiriaco-summit':
    name: 'Chevron Chiriaco Summit'
    id: '6d6aea30-baf4-11e8-a749-052732658139'
    location: [33.660847, -115.720135]
    amenities: ['water', 'propane', 'gas']
    prices:
      water: 0

  'cottonwood-visitor-center':
    name: 'Cottonwood Visitor Center'
    id: 'bfb56f20-baf6-11e8-b24b-883a4f229ab0'
    location: [33.748603, -115.823964]
    amenities: ['dump', 'water']
    prices:
      water: 5
      dump: 5

  'winco-foods-indio':
    name: 'Winco Foods Indio'
    id: 'f3771930-baf6-11e8-b1f3-de0d96c4e95b'
    location: [33.739575, -116.213104]
    amenities: ['groceries', 'trash']



module.exports = _.map amenities, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
