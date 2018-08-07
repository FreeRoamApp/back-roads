# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

categories =
  'starting-out':
    name: 'Starting Out'
    description: 'Products to get you ready to start RVing'
    data:
      defaultProductId: 'camco-plastic-wheel-chocks'
  'maintenance':
    name: 'Maintenance'
    description: 'Products to keep your RV in tip-top shape'
    data:
      defaultProductId: 'bio-pak-digester'

module.exports = _.map categories, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
