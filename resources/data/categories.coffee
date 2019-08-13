# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

# TODO: filtering, sorting

categories =
  'starting-out':
    id: '223c7020-bbe2-11e9-87d9-5e5f8363bc85'
    name: 'Starting out'
    description: 'Products to get you ready to start with your {home}'
    priority: 2
    filters:
      rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some', 'all']
    data:
      sortFilters:
        rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
        experience: ['none', 'little']
        hookupPreference: ['none', 'some', 'all']

  # 'maintenance':
  #   name: 'Maintenance'
  #   description: 'Products to keep your RV in tip-top shape'
  #   priority: 1

  'boondocking':
    id: '22557660-bbe2-11e9-8964-03f8a3ff78ec'
    name: 'Boondocking'
    description: 'Everything you need to get started with boondocking (and more!)'
    priority: 0
    filters:
      rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some']


  'outdoors':
    id: '8f87c410-bd7a-11e9-b8e0-402ab125f3ff'
    name: 'Outdoors'
    description: 'Products to help you enjoy the great outdoors even more'
    priority: 3
    filters:
      rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
      experience: ['none', 'little', 'some', 'lots']
      hookupPreference: ['none', 'some', 'all']



module.exports = _.map categories, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
