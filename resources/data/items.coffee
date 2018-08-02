# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

items =
  'surge-protector':
    name: 'Surge Protector'
    why: 'Electricity is not something to mess around with - one bad electrical hookup and you could fry your internal RV systems. Surge protectors will let you know when a hookup is going to cause problems, and even prevent issues with power surges and outages.'
    what: 'First off, you’ll need the correct amperage for your RV: 30amp or 50amp. You’ll probably want something that’s weather-proof.'

  'sealant':
    name: 'Sealant'
    why: 'RVs are notorious for leaking and causing water damage - often to the extent that fixing it costs more than the RV is worth. Making sure everything is sealed up properly will save you from that headache.'
    what: '''The are 3 common sealants to use. Sealant Tape (eg. Eternabond) is commonly used to seal vents and other openings on roofs. Self-leveling sealant can be used instead of tape on the roof, or complementary to tape for seams with non-straight edges. Non-sag sealant is for seams on the sides of your 

          You’ll need to make sure that the sealant you’re using works with your roof-type. We also recommend against silicone sealants since they’re a pain to inevitably fix (you need to fully remove any silicone sealant before applying more).'''

module.exports = _.map items, (value, id) -> _.defaults {id}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
