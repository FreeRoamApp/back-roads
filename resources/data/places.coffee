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


module.exports = _.map places, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
