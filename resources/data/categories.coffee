# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

categories =
  'starting-out':
    name: 'Starting Out'
    description: 'Products to get you ready to start RVing'
    priority: 0
    data:
      defaultProductId: 'camco-plastic-wheel-chocks'
  'maintenance':
    name: 'Maintenance'
    description: 'Products to keep your RV in tip-top shape'
    priority: 1
    data:
      defaultProductId: 'bio-pak-digester'
  'boondocking':
    name: 'Boondocking'
    description: 'Solar, generators, and everything you need to boondock'
    priority: 2
    data:
      defaultProductId: 'renogy-100w-solar-panel-mono'

module.exports = _.map categories, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
