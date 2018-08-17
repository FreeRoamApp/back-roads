# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

places =
  'old-settlers-rv-park':
    name: 'Old Settlers RV Park'
    location: [30.52792, -97.63349]

module.exports = _.map places, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
