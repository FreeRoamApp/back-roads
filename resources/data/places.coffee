# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: 'view satellite' link
# TODO: distanceTo: calculate from other places in database? or manually input
# just AZ for now (fall/winter)

places =
  'snyder-hill-blm-campground':
    name: 'Snyder Hill BLM'
    location: [32.158132, -111.115281]
    siteCount:
      99: 30
    crowdLevel: {winter: 8, spring: 6, summer: 3, fall: 6}
    noiseLevel: {day: 5, night: 4}
    shadeLevel: 0
    roadDifficulty: 2
    cellSignal: {att: {signal: 7, type: '4g'}, verizon: {signal: 7, type: '4g'}, sprint: {signal: 7, type: '3g'}, tmobile: {signal: 7, type: '4g'}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: '8yzp-bm0qfY'}
    ]

  'saddle-mountain-blm-campground':
    name: 'Saddle Mountain BLM'
    location: [33.464512, -113.036644]
    siteCount:
      99: 15
    crowdLevel: {winter: 3, spring: 2, summer: 2, fall: 2}
    noiseLevel: {day: 2, night: 2}
    shadeLevel: 0
    roadDifficulty: 4
    cellSignal: {att: {signal: 5, type: '4g'}, verizon: {signal: 5, type: '4g'}, sprint: {signal: 5, type: '3g'}, tmobile: {signal: 0}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'FNpfindtHiY'}
      {sourceType: 'youtube', sourceId: 'bU5baE6D2kw', timestamp: '1m56s'}
    ]

  'scaddan-wash-blm-campground':
    name: 'Scaddan Wash BLM'
    location: [33.661132, -114.186548]
    drivingInstructions: ''
    siteCount:
      99: 50
    crowdLevel: {winter: 8, spring: 5, summer: 2, fall: 5}
    noiseLevel: {day: 6, night: 6}
    shadeLevel: 0
    roadDifficulty: 1
    cellSignal: {att: {signal: 5, type: '4g'}, verizon: {signal: 8, type: '4g', speed: 'slow'}, sprint: {signal: 6, type: '3g'}, tmobile: {signal: 5, type: '4g'}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'rH3wRuU3xNk'}
    ]

  'scaddan-wash-blm-campground':
    name: 'Scaddan Wash BLM'
    location: [33.661132, -114.186548]
    siteCount:
      99: 50
    crowdLevel: {winter: 8, spring: 5, summer: 2, fall: 5}
    noiseLevel: {day: 6, night: 6}
    shadeLevel: 0
    roadDifficulty: 0
    cellSignal: {att: {signal: 5, type: '4g'}, verizon: {signal: 8, type: '4g', speed: 'slow'}, sprint: {signal: 6, type: '3g'}, tmobile: {signal: 5, type: '4g'}}
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'rH3wRuU3xNk'}
    ]

  # 'forest-road-687':
  #   name: 'Forest Road 687'
  #   location: [31.860536, -110.015574]
  #   siteCount:
  #     35: 5
  #     25: 5
  #   crowdLevel: {winter: 3, spring: 3, summer: 2, fall: 3}
  #   noiseLevel: {day: 1, night: 1}
  #   shadeLevel: 3
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
    siteCount:
      35: 5
      25: 15
    crowdLevel: {winter: 3, spring: 3, summer: 2, fall: 3}
    noiseLevel: {day: 3, night: 2}
    shadeLevel: 0
    roadDifficulty: 3
    cellSignal: {att: {signal: 6, type: '4g'}, verizon: {signal: 6, type: '4g'}, tmobile: {signal: 4, type: '4g'}}
    safetyLevel: 5
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'pwYfAMLVTsQ'}
    ]

  'craggy-wash-blm':
    name: 'Craggy Wash BLM'
    location: [34.586301, -114.367222]
    siteCount:
      99: 40
    crowdLevel: {winter: 6, spring: 5, summer: 3, fall: 5}
    fullnessLevel: {winter: 6, spring: 4, summer: 2, fall: 4}
    noiseLevel: {day: 3, night: 2}
    shadeLevel: 0
    roadDifficulty: 3
    cellSignal: {att: {signal: 5, type: '4g', speed: 'fast'}, verizon: {signal: 6, type: '4g'}, sprint: {signal: 7, type: '3g'}, tmobile: {signal: 0, type: '4g', speed: 'fast'}}
    safetyLevel: 8
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    videos: [
      {sourceType: 'youtube', sourceId: 'Ta9ZMuUSZUg'}
      {sourceType: 'youtube', sourceId: 'cTZHqYZwpyg'}
    ]

  'indian-bread-rocks-blm':
    name: 'Indian Bread Rocks BLM'
    location: [32.238663, -109.499735]
    drivingInstructions: 'Turn on to S Happy Camp Canyon (well-maintained gravel road) from Apache Pass Rd. 3 more miles before you get to the BLM area.'
    siteCount:
      35: 4
      25: 15
    crowdLevel: {winter: 6, spring: 5, summer: 3, fall: 5}
    fullnessLevel: {winter: 3, spring: 2, summer: 1, fall: 2}
    noiseLevel: {day: 1, night: 1}
    shadeLevel: 0
    roadDifficulty: 3
    cellSignal: {att: {signal: 7, type: '4g'}, verizon: {signal: 7, type: '4g'},  tmobile: {signal: 3, type: '4g'}}
    safetyLevel: 8
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: {pitToilet: true}
    videos: [
      {sourceType: 'youtube', sourceId: '_SXesBB6x8I'}
    ]

  'bombos-pond':
    name: 'Bombo\'s Pond'
    location: [36.881623, -116.753584]
    drivingInstructions: 'Right off Highway 95. You can go over the hill by the pond for a little more privacy.'
    siteCount:
      99: 20
    crowdLevel: {winter: 7, spring: 7, summer: 5, fall: 7}
    fullnessLevel: {winter: 4, spring: 4, summer: 2, fall: 4}
    noiseLevel: {day: 5, night: 4}
    shadeLevel: 0
    roadDifficulty: 1
    cellSignal: {att: {signal: 2, type: '4g'}, verizon: {signal: 2, type: '4g'}}
    safetyLevel: 5
    minPrice: 0, maxPrice: 0, hasFreshWater: false, hasSewage: false, has30Amp: false, has50Amp: false
    maxDays: 14
    restrooms: null
    videos: [
      {sourceType: 'youtube', sourceId: 'NqjCGkeWMjg'}
    ]

  # rockhouse campground
  # jumbo rocks joshua tree
  # joshua tree south


module.exports = _.map places, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
