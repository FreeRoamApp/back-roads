# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

categories =
  # 'starting-out':
  #   name: 'Starting out'
  #   description: 'Products to get you ready to start with an RV'
  #   priority: 2
  # 'maintenance':
  #   name: 'Maintenance'
  #   description: 'Products to keep your RV in tip-top shape'
  #   priority: 1
  'boondocking':
    name: 'Boondocking'
    description: 'Everything you need to get started with boondocking (and more!)'
    priority: 0

module.exports = _.map categories, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
