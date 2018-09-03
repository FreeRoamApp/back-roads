# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

cknex = require '../../services/cknex'
config = require '../../config'

groups =
  'free-roam':
    name: 'Free Roam'
    id: 'e49d82d0-a0db-11e8-9db6-4e284e268fd1'
    description: ''
  'boondocking':
    name: 'Boondocking'
    id: '587890f0-ae60-11e8-a27c-80ac194a588d'
    description: ''

module.exports = _.map groups, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
