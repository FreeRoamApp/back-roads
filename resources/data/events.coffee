# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

cknex = require '../../services/cknex'
# console.log cknex.getTimeUuid()

events =
  'open-roads-vanlife-festival-2019':
    name: 'Open Roads Vanlife Festival'
    id: '532fb3e0-ba08-11e8-b313-6066b1415760'
    location: {lat: 44.832571, lon: -116.047515}
    details: 'details....'
    startTime: new Date(2019, 6, 11, 0, 0, 0)
    endTime: new Date(2019, 6, 14, 0, 0, 0)
    address:
      locality: 'McCall'
      administrativeArea: 'ID'
    prices:
      all: 39
    contact:
      website: 'https://openroadsfest.com'


module.exports = _.map events, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
