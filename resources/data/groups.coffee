# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

groups =
  'free-roam':
    name: 'Free Roam'
    uuid: 'e49d82d0-a0db-11e8-9db6-4e284e268fd1'
    description: ''

module.exports = _.map groups, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
