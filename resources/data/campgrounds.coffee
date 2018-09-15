# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: 'view satellite' link
# TODO: distanceTo: calculate from other campgrounds in database? or manually input
# just AZ for now (fall/winter)

campgrounds =
  'snyder-hill-blm':
    name: 'Snyder Hill BLM'
    location: [32.158132, -111.115281]
    address:
      locality: 'Tucson'
      administrativeArea: 'AZ'
    siteCount:
      99: 30
    crowds: {winter: 4, spring: 3, summer: 2, fall: 3}
    noise: {day: 3, night: 2}
    shade: 1
    roadDifficulty: 2
    cellSignal: {att: {signal: 3, type: '4g'}, verizon: {signal: 3, type: '4g'}, sprint: {signal: 3, type: '3g'}, tmobile: {signal: 3, type: '4g'}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: '8yzp-bm0qfY'}
    ]

  'saddle-mountain-blm':
    name: 'Saddle Mountain BLM'
    location: [33.464512, -113.036644]
    address:
      locality: 'Tonopah'
      administrativeArea: 'AZ'
    siteCount:
      99: 15
    crowds: {winter: 2, spring: 1, summer: 1, fall: 1}
    noise: {day: 1, night: 1}
    shade: 1
    roadDifficulty: 2
    cellSignal: {att: {signal: 2, type: '4g'}, verizon: {signal: 2, type: '4g'}, sprint: {signal: 2, type: '3g'}, tmobile: {signal: 0}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'FNpfindtHiY'}
      {sourceType: 'youtube', sourceId: 'bU5baE6D2kw', timestamp: '1m56s'}
    ]

  'scaddan-wash-blm':
    name: 'Scaddan Wash BLM'
    location: [33.661132, -114.186548]
    address:
      locality: 'Quartzsite'
      administrativeArea: 'AZ'
    drivingInstructions: ''
    siteCount:
      99: 50
    crowds: {winter: 4, spring: 3, summer: 1, fall: 3}
    noise: {day: 3, night: 3}
    shade: 1
    roadDifficulty: 1
    cellSignal: {att: {signal: 2, type: '4g'}, verizon: {signal: 4, type: '4g', speed: 'slow'}, sprint: {signal: 3, type: '3g'}, tmobile: {signal: 2, type: '4g'}}
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
  #   crowds: {winter: 3, spring: 3, summer: 2, fall: 3}
  #   noise: {day: 1, night: 1}
  #   shade: 3
  #   roadDifficulty: 7
  #   cellSignal: {att: {signal: 3, type: '4g'}, verizon: {signal: 6, type: '4g'}, tmobile: {signal: 6, type: '4g'}}
  #   minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
  #   maxDays: 14
    # videos: [
    #   {sourceType: 'youtube', sourceId: 'rH3wRuU3xNk'}
    # ]

  'darby-well-road':
    name: 'Darby Well Road'
    location: [32.339270, -112.849561]
    address:
      locality: 'Ajo'
      administrativeArea: 'AZ'
    siteCount:
      35: 5
      25: 15
    crowds: {winter: 2, spring: 2, summer: 1, fall: 2}
    noise: {day: 2, night: 1}
    shade: 1
    roadDifficulty: 2
    cellSignal: {att: {signal: 3, type: '4g'}, verizon: {signal: 3, type: '4g'}, tmobile: {signal: 2, type: '4g'}}
    safety: 5
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'pwYfAMLVTsQ'}
    ]

  'craggy-wash-blm':
    name: 'Craggy Wash BLM'
    location: [34.586301, -114.367222]
    address:
      locality: 'Lake Havasu City'
      administrativeArea: 'AZ'
    siteCount:
      99: 40
    crowds: {winter: 3, spring: 2, summer: 1, fall: 2}
    fullness: {winter: 3, spring: 2, summer: 1, fall: 2}
    noise: {day: 2, night: 1}
    shade: 1
    roadDifficulty: 2
    cellSignal: {att: {signal: 2, type: '4g', speed: 'fast'}, verizon: {signal: 3, type: '4g'}, sprint: {signal: 3, type: '3g'}, tmobile: {signal: 0, type: '4g', speed: 'fast'}}
    safety: 4
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'Ta9ZMuUSZUg'}
      {sourceType: 'youtube', sourceId: 'cTZHqYZwpyg'}
    ]

  'indian-bread-rocks-blm':
    name: 'Indian Bread Rocks BLM'
    location: [32.238663, -109.499735]
    address:
      locality: 'Bowie'
      administrativeArea: 'AZ'
    drivingInstructions: 'Turn on to S Happy Camp Canyon (well-maintained gravel road) from Apache Pass Rd. 3 more miles before you get to the BLM area.'
    siteCount:
      35: 4
      25: 15
    crowds: {winter: 3, spring: 2, summer: 1, fall: 2}
    fullness: {winter: 2, spring: 1, summer: 1, fall: 1}
    noise: {day: 1, night: 1}
    shade: 1
    roadDifficulty: 3
    cellSignal: {att: {signal: 3, type: '4g'}, verizon: {signal: 3, type: '4g'},  tmobile: {signal: 2, type: '4g'}}
    safety: 4
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: {pitToilet: true}
    videos: [
      {sourceType: 'youtube', sourceId: '_SXesBB6x8I'}
    ]

  'bombos-pond':
    name: 'Bombo\'s Pond'
    location: [36.881623, -116.753584]
    address:
      locality: 'Beatty'
      administrativeArea: 'NV'
    drivingInstructions: 'Right off Highway 95. You can go over the hill by the pond for a little more privacy.'
    siteCount:
      99: 20
    crowds: {winter: 3, spring: 3, summer: 2, fall: 3}
    fullness: {winter: 2, spring: 2, summer: 1, fall: 2}
    noise: {day: 3, night: 2}
    shade: 1
    roadDifficulty: 1
    cellSignal: {att: {signal: 2, type: '4g'}, verizon: {signal: 2, type: '4g'}}
    safety: 2
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: 'NqjCGkeWMjg'}
    ]

  # rockhouse campground
  # jumbo rocks joshua tree
  # joshua tree south


module.exports = _.map campgrounds, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
