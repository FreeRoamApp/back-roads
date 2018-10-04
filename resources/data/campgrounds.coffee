# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: 'view satellite' link
# TODO: distanceTo: calculate from other campgrounds in database? or manually input
# just AZ for now (warmer)
cknex = require '../../services/cknex'
console.log cknex.getTimeUuid()

campgrounds =
  'snyder-hill-blm':
    name: 'Snyder Hill BLM'
    id: 'b01d8540-b95a-11e8-bd0b-850399f93208'
    location: [32.158132, -111.115281]
    address:
      locality: 'Tucson'
      administrativeArea: 'AZ'
    siteCount:
      99: 30
    crowds: {winter: {value: 4, count: 1}, spring: {value: 3, count: 1}, summer: {value: 2, count: 1}, fall: {value: 3, count: 1}}
    fullness: {winter: {value: 4, count: 1}, springs: 3, summer: {value: 2, count: 1}, fall: {value: 3, count: 1}}
    noise: {day: {value: 3, count: 1}, night: {value: 2, count: 1}}
    shade: {value: 1, count: 1}
    safety: {value: 4, count: 1}
    roadDifficulty: {value: 2, count: 1}
    cellSignal: {att_lte: {signal: 3, count: 1}, verizon_lte: {signal: 3, count: 1}, sprint: {value: 3, count: 1, type: '3g'}, tmobile_lte: {signal: 3, count: 1}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: '8yzp-bm0qfY'}
    ]

  'saddle-mountain-blm':
    name: 'Saddle Mountain BLM'
    id: 'bdc8f8a0-b95a-11e8-9f50-694a5cc55d04'
    location: [33.464512, -113.036644]
    address:
      locality: 'Tonopah'
      administrativeArea: 'AZ'
    siteCount:
      99: 15
    crowds: {winter: {value: 2, count: 1}, spring: {value: 1, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 2, count: 1}, spring: {value: 1, count: 1}, summer: {value: 1, count: 1}, fall: {value: 1, count: 1}}
    noise: {day: {value: 1, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    safety: {value: 4, count: 1}
    roadDifficulty: {value: 2, count: 1}
    cellSignal: {att_lte: {signal: 2, count: 1}, verizon_lte: {signal: 2, count: 1}, sprint: {value: 2, count: 1, type: '3g'}, tmobile: {value: 0, count: 1}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'FNpfindtHiY'}
      {sourceType: 'youtube', sourceId: 'bU5baE6D2kw', timestamp: '1m56s'}
    ]

  'scaddan-wash-blm':
    name: 'Scaddan Wash BLM'
    id: 'caba91e0-b95a-11e8-bd4b-a2e26b5759cf'
    location: [33.661132, -114.186548]
    address:
      locality: 'Quartzsite'
      administrativeArea: 'AZ'
    drivingInstructions: ''
    siteCount:
      99: 50
    crowds: {winter: {value: 4, count: 1}, spring: {value: 3, count: 1}, summer: {value: 1, count: 1}, fall: {value: 3, count: 1}}
    fullness: {winter: {value: 3, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    noise: {day: {value: 3, count: 1}, night: {value: 3, count: 1}}
    shade: {value: 1, count: 1}
    safety: {value: 4, count: 1}
    roadDifficulty: {value: 1, count: 1}
    cellSignal: {att_lte: {signal: 2, count: 1}, verizon_lte: {signal: 4, count: 1, speed: 'slow'}, sprint: {value: 3, count: 1, type: '3g'}, tmobile_lte: {signal: 2, count: 1}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'rH3wRuU3xNk'}
    ]

  # 'forest-road-687':
  #   name: 'Forest Road 687'
  #   location: [31.860536, -110.015574]
  #   address:
  #     locality: 'Tombstone'
  #     administrativeArea: 'AZ'
  #   siteCount:
  #     35: 5
  #     25: 5
  #   crowds: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 2, count: 1}, fall: {value: 3, count: 1}}
  #   noise: {day: {value: 1, count: 1}, night: {value: 1, count: 1}}
  #   shade: {value: 3, count: 1}
  #   roadDifficulty: {value: 7, count: 1}
  #   cellSignal: {att_lte: {signal: 3, count: 1}, verizon_lte: {signal: 6, count: 1}, tmobile_lte: {signal: 6, count: 1}}
  #   minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
  #   maxDays: 14
    # videos: [
    #   {sourceType: 'youtube', sourceId: 'rH3wRuU3xNk'}
    # ]

  'darby-well-road':
    name: 'Darby Well Road'
    id: 'e0c7b620-b95a-11e8-aa35-9ccab29abe44'
    location: [32.339270, -112.849561]
    address:
      locality: 'Ajo'
      administrativeArea: 'AZ'
    siteCount:
      35: 5
      25: 15
    crowds: {winter: {value: 2, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 2, count: 1}, fall: {value: 1, count: 1}}
    noise: {day: {value: 2, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 2, count: 1}
    cellSignal: {att_lte: {signal: 3, count: 1}, verizon_lte: {signal: 3, count: 1}, tmobile_lte: {signal: 2, count: 1}}
    safety: {value: 3, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'pwYfAMLVTsQ'}
    ]

  'craggy-wash-blm':
    name: 'Craggy Wash BLM'
    id: 'e7815c50-b95a-11e8-a52d-67644798c673'
    location: [34.586301, -114.367222]
    address:
      locality: 'Lake Havasu City'
      administrativeArea: 'AZ'
    siteCount:
      99: 40
    crowds: {winter: {value: 3, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 3, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    noise: {day: {value: 2, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 2, count: 1}
    cellSignal: {att_lte: {signal: 2, count: 1, speed: 'fast'}, verizon_lte: {signal: 3, count: 1}, sprint: {value: 3, count: 1, type: '3g'}, tmobile_lte: {signal: 0, count: 1, speed: 'fast'}}
    safety: {value: 4, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'Ta9ZMuUSZUg'}
      {sourceType: 'youtube', sourceId: 'cTZHqYZwpyg'}
    ]

  'indian-bread-rocks-blm':
    name: 'Indian Bread Rocks BLM'
    id: 'eec4cbf0-b95a-11e8-beb1-a9dd11964986'
    location: [32.238663, -109.499735]
    address:
      locality: 'Bowie'
      administrativeArea: 'AZ'
    drivingInstructions: 'Turn on to S Happy Camp Canyon (well-maintained gravel road) from Apache Pass Rd. 3 more miles before you get to the BLM area.'
    siteCount:
      35: 4
      25: 15
    crowds: {winter: {value: 3, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 2, count: 1}, spring: {value: 1, count: 1}, summer: {value: 1, count: 1}, fall: {value: 1, count: 1}}
    noise: {day: {value: 1, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 3, count: 1}
    cellSignal: {att_lte: {signal: 3, count: 1}, verizon_lte: {signal: 3, count: 1},  tmobile_lte: {signal: 2, count: 1}}
    safety: {value: 4, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: {pitToilet: true}
    videos: [
      {sourceType: 'youtube', sourceId: '_SXesBB6x8I'}
    ]

  'bombos-pond':
    name: 'Bombo\'s Pond'
    id: 'f443a830-b95a-11e8-a4bf-2d01b29b84ce'
    location: [36.881623, -116.753584]
    address:
      locality: 'Beatty'
      administrativeArea: 'NV'
    drivingInstructions: 'Right off Highway 95. You can go over the hill by the pond for a little more privacy.'
    siteCount:
      99: 20
    crowds: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 2, count: 1}, fall: {value: 3, count: 1}}
    fullness: {winter: {value: 2, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    noise: {day: {value: 3, count: 1}, night: {value: 2, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 1, count: 1}
    cellSignal: {att_lte: {signal: 2, count: 1}, verizon_lte: {signal: 2, count: 1}}
    safety: {value: 3, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: 'NqjCGkeWMjg'}
    ]

  'american-girl-mine-blm':
    name: 'American Girl Mine BLM'
    id: 'cabc22c0-babe-11e8-8e13-181478e84c85'
    location: [32.836784, -114.812061]
    address:
      locality: 'Obregon'
      administrativeArea: 'CA'
    # drivingInstructions: ''
    siteCount:
      99: 50
    crowds: {winter: {value: 3, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 2, count: 1}, spring: {value: 1, count: 1}, summer: {value: 1, count: 1}, fall: {value: 1, count: 1}}
    noise: {day: {value: 2, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 2, count: 1}
    cellSignal: {att_lte: {signal: 1, count: 1}, verizon_lte: {signal: 4, count: 1}}
    safety: {value: 4, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: '5kI5V3rn0vo'}
    ]

  'blair-valley':
    name: 'Blair Valley'
    id: 'b3ec0760-bae4-11e8-b8ae-1f51c09be6da'
    location: [33.037322, -116.410416]
    address:
      locality: 'Julian'
      administrativeArea: 'CA'
    # # drivingInstructions: ''
    siteCount:
      99: 50
    crowds: {winter: {value: 2, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 2, count: 1}, spring: {value: 2, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    noise: {day: {value: 1, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 3, count: 1}
    cellSignal: {att_lte: {signal: 3, count: 1}, verizon_lte: {signal: 3, count: 1}, tmobile_lte: {signal: 3, count: 1}}
    safety: {value: 4, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: 'IGftiG2oTFA', timestamp: '6m30s'}
    ]

  'joshua-tree-blm-south':
    name: 'Joshua Tree BLM South'
    id: '4e8c7540-baf2-11e8-8e0a-97f6c311604a'
    location: [33.674494, -115.801903]
    address:
      locality: 'Chiriaco Summit'
      administrativeArea: 'CA'
    # # # drivingInstructions: ''
    siteCount:
      99: 25
    crowds: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 1, count: 1}, fall: {value: 3, count: 1}}
    fullness: {winter: {value: 4, count: 1}, spring: {value: 4, count: 1}, summer: {value: 1, count: 1}, fall: {value: 3, count: 1}}
    noise: {day: {value: 2, count: 1}, night: {value: 2, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 3, count: 1}
    cellSignal: {att_lte: {signal: 4, count: 1}, verizon_lte: {signal: 4, count: 1}, tmobile_lte: {signal: 3, count: 1}, sprint_lte: {signal: 3, count: 1}}
    safety: {value: 4, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: 'Qb-mqJyzGeE'}
    ]

  # permit req
  # 'government-wash':
  #   name: 'Government Wash'
  #   id: 'af30b550-bafc-11e8-ab2b-d533ac942e4d'
  #   location: [36.133394, -114.837833]
  #   address:
  #     locality: 'Las Vegas'
  #     administrativeArea: 'NV'
  #   # # # drivingInstructions: ''
  #   siteCount:
  #     99: 20
  #   # crowds: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 1, count: 1}, fall: {value: 3, count: 1}}
  #   # fullness: {winter: {value: 4, count: 1}, spring: {value: 4, count: 1}, summer: {value: 1, count: 1}, fall: {value: 3, count: 1}}
  #   # noise: {day: {value: 2, count: 1}, night: {value: 2, count: 1}}
  #   # shade: {value: 1, count: 1}
  #   # roadDifficulty: {value: 3, count: 1}
  #   # cellSignal: {att_lte: {signal: 4, count: 1}, verizon_lte: {signal: 4, count: 1}, tmobile_lte: {signal: 3, count: 1}, sprint_lte: {signal: 3, count: 1}}
  #   # safety: {value: 4, count: 1}
  #   # minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
  #   # maxDays: 14
  #   # restrooms: null
  #   videos: [
  #     {sourceType: 'youtube', sourceId: 'tZJ6cGPsy_o '}
  #   ]

  'rockhouse':
    name: 'Rockhouse'
    id: 'e78b4b20-c391-11e8-9a3e-74441ff1beb7'
    location: [33.294480, -116.290165]
    address:
      locality: 'Borrego Springs'
      administrativeArea: 'CA'
    # # # # drivingInstructions: ''
    siteCount:
      99: 50
    crowds: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    fullness: {winter: {value: 3, count: 1}, spring: {value: 3, count: 1}, summer: {value: 1, count: 1}, fall: {value: 2, count: 1}}
    noise: {day: {value: 2, count: 1}, night: {value: 1, count: 1}}
    shade: {value: 1, count: 1}
    roadDifficulty: {value: 2, count: 1}
    cellSignal: {att_lte: {signal: 3, count: 1}, verizon_lte: {signal: 3, count: 1}, tmobile_lte: {signal: 3, count: 1}, sprint_lte: {signal: 3, count: 1}}
    safety: {value: 4, count: 1}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: 'SVBcMpFtWWs'}
    ]

  # geekstreamers:
  # white mountain road dispersed
  # franklin basin road dispersed
  # twin lakes
  # san luis state wildlife area
  # upper teton view
  # nomad view
  # mchood park (winslow az but cold in winter: {value: 4, count: 1}9/21 in jan)




  # rockhouse campground
  # jumbo rocks joshua tree
  # joshua tree south
  # valley of fire nevada, A8vEsqSssRE, MFt5XBe59cA timestamp 3m0s



module.exports = _.map campgrounds, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
