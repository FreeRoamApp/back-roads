# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

Subscription = require '../../models/subscription'
cknex = require '../../services/cknex'
config = require '../../config'

groups =
  # 'free-roam':
  #   name: 'Free Roam'
  #   id: 'e49d82d0-a0db-11e8-9db6-4e284e268fd1'
  #   description: ''
  'freeroam':
    name: 'FreeRoam'
    id: 'e49d82d0-a0db-11e8-9db6-4e284e268fd1'
    description: ''
    data:
      defaultNotifications: [
        # Subscription.TYPES.GROUP_MESSAGE
        Subscription.TYPES.GROUP_MENTION
      ]

module.exports = _.map groups, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
