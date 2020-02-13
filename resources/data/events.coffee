# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

cknex = require '../../services/cknex'
console.log cknex.getTimeUuid()

events =
  'xscapers-annual-bash-2020':
    name: 'Xscapers Annual Bash'
    id: '2fe03740-d8be-11e9-a0dd-92f925ad5876'
    location: {lat: 34.447061, lon: -114.26065}
    details: '''
This is it, the RV event of the year! It’s the World Series, Oscar night, and the Met Gala all rolled into one. It’s New Year’s Eve for 7 nights, it’s Christmas meets Chanukah. It’s like payday and your tax refund landed on the same day. It’s the thing people will be talking about for the next year. It’s the 5th Xscapers Annual Bash!

The Xscapers Annual Bash is back at our rodeo grounds home in Lake Havasu City Arizona. Come join us for the social event of the RVers’ year. Over 600 working-age RVers from all walks of life will descend on the edge of the Colorado River for a week of excitement, entertainment, education, games, fun, romance, and new and old friendships!

If you’ve never been to an Xscapers Annual Bash, you’ll be shocked! This ain’t your grandma’s RV rally! The days are filled with speakers covering all topics RV and RV life related including boondocking, solar, working on the road, cooking, and hobbies. The evenings are filled with a mobile party like you’ve never seen at an RV event. Dance the night away at a rave, sing out loud to classic rock and 80s bands, compete in fun games, or participate in margarita contests. Join in the theme nights and hang out by the fire till sunrise. Try craft brews, share your favorite guacamole recipe, or just try one of the dozens on offer. Indulge in local food trucks, share drinks and ideas with like minded RVers, and be part of a movement! Get out of your rig, and get to living at the Xscapers Annual Bash!
'''
    startTime: new Date(2020, 0, 11, 9, 0, 0)
    endTime: new Date(2020, 0, 19, 12, 0, 0)
    address:
      locality: 'Lake Havasu'
      administrativeArea: 'AZ'
    prices:
      all: 300
    contact:
      website: 'https://xscapers.com/event/xscapers-annual-bash-2020/'


  'boondocking-bash-2019':
    name: 'Boondocking Bash'
    id: '48693570-0828-11ea-a63b-881378f5bad7'
    location: {lat: 33.645468, lon: -114.325596}
    details: '''
Dome Rock BLM campground Quartzsite Arizona

There will be no fee to attend everyone attending will receive a magnet

Nothing will be provided except an opportunity to meet and camp with other boondockers..
No toilets water or trash provided.  but can be found in town
 You must be self sufficient /contained ready to boondock and have a good time
... We might have music even live music and maybe a 🎥 movie night
.
The only real goal will be to keep the main 🔥 fire pit going each night
so bring wood if you can.... we can never have too much wood.
'''
    startTime: new Date(2019, 10, 23, 10, 0, 0)
    endTime: new Date(2019, 11, 7, 10, 0, 0)
    address:
      locality: 'Quartzite'
      administrativeArea: 'AZ'
    prices:
      all: 0
    contact:
      website: 'https://www.facebook.com/events/418553845531600/'


  'vancouver-van-life-2019':
    name: 'Vancouver Van Life Christmas Eve'
    id: '48693570-0828-11ea-a63b-881378f5bad7'
    location: {lat: 49.278305, lon: -123.229301}
    details: '''
    Everyone welcome. At Spanish Banks far end parking lot near the dog park.
'''
    startTime: new Date(2019, 11, 24, 14, 0, 0)
    endTime: new Date(2019, 11, 24, 20, 0, 0)
    address:
      locality: 'Vancouver'
      administrativeArea: 'BC'
    prices:
      all: 0
    contact:
      website: 'https://www.youtube.com/watch?v=h7Pm77FHFWg'


module.exports = _.map events, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
