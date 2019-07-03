# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

config = require '../../config'

cknex = require '../../services/cknex'
console.log cknex.getTimeUuid()

events =
  'open-roads-vanlife-festival-2019':
    name: 'Open Roads Vanlife Festival'
    id: '532fb3e0-ba08-11e8-b313-6066b1415760'
    location: {lat: 44.832571, lon: -116.047515}
    details: 'Join us July 11th – 14th for an epic, three-night campout in the mountains of Idaho as we celebrate all that van life has to offer. The inaugural Open Roads Fest is an all-ages van life festival packed with outdoor adventure, workshops, and social events for the road trippin’ community.'
    startTime: new Date(2019, 6, 11, 0, 0, 0)
    endTime: new Date(2019, 6, 14, 0, 0, 0)
    address:
      locality: 'McCall'
      administrativeArea: 'ID'
    prices:
      all: 39
    contact:
      website: 'https://openroadsfest.com'



  'colorado-vanlife-gathering-2019':
    name: 'Colorado Vanlife Gathering'
    id: 'ea0a62c0-9dc8-11e9-9401-a2cf2899fa8b'
    location: {lat: 39.376966, lon: -106.997352}
    details: '''
Vanlife + Tiny House, Tiny Footprint are partnering to bring you the FOURTH Colorado Vanlife Gathering! Ticket includes two nights camping in the beautiful Dallenbach Ranch in Basalt, Colorado. A portion of your ticket will be donated to The Trust for Public Land.

THIS IS A FAMILY-FRIENDLY, PET-FRIENDLY EVENT (ALL ARE WELCOME). Vans, buses, trucks, cars, motorbikes, swags, RVs are welcome - bring what ya got! The only requirement is that you have an open mind, enjoy alternative ways of living, and want to meet some interesting people.

Bathrooms on site. Off-grid electric setups are welcome, but NO GENERATORS PLEASE.
There is NO POTABLE WATER on site. Please bring enough water and food for the weekend. Pack it in, pack it out.
'''
    startTime: new Date(2019, 6, 12, 0, 0, 0)
    endTime: new Date(2019, 6, 14, 0, 0, 0)
    address:
      locality: 'Basalt'
      administrativeArea: 'CO'
    prices:
      all: 50
    contact:
      website: 'https://www.vanlife.com.au/vanlifegatherings/colorado'



  'xscapers-alaska-convergence-2019':
    name: 'Xscapers Alaska Convergence'
    id: '6136e420-9dcb-11e9-9b5e-b5edc096af73'
    location: {lat: 63.199440, lon: -145.5087}
    details: '''
Here is a video of hosts Gary & Stacy in the area from 2017: https://youtu.be/3OuloWaEP9s.  This is an old pipeline construction camp that is BLM land and every April over 10,000 RV’s park in this valley  for a combined snowmachine/skiing event called Arctic Man. Any size rig can park and there will be plenty of room to spread out. In July, the temperatures should be perfect for our gathering!

The nearest services are 67 miles in Delta Junction or 85 miles to Glenallen so provisioning is necessary before arrival.  The closest dump station is in Delta Junction or Glenallen so come with full fresh and empty black/grey. Our campsite is below the Gulkana Glacier and several hiking trails are available from camp towards the glacier.
'''
    startTime: new Date(2019, 6, 18, 0, 0, 0)
    endTime: new Date(2019, 6, 22, 0, 0, 0)
    address:
      locality: 'Isabel Pass'
      administrativeArea: 'AK'
    prices:
      all: 0
    contact:
      website: 'https://xscapers.com/event/alaska-convergence/'



  'xscapers-rhythms-on-the-rio-convergence-2019':
    name: 'Xscapers Rhythms on the Rio Convergence'
    id: 'd55b1970-9dcb-11e9-a350-d0bae4637aee'
    location: {lat: 37.6700041, lon: -106.6397638}
    details: '''
Join Xscapers for a small town music festival High in the Rocky Mountains. The Rhythms on the Rio music festival will celebrate its 14th anniversary of providing music lessons to kids in town. Xscapers will be there this year, with a reserved camping area and the stage just a very short walk away. 3 days of music covers all genres, there will be something for everyone!
'''
    startTime: new Date(2019, 7, 2, 0, 0, 0)
    endTime: new Date(2019, 7, 4, 0, 0, 0)
    address:
      locality: 'South Fork'
      administrativeArea: 'CO'
    prices:
      all: 60
    contact:
      website: 'https://xscapers.com/event/rhythms-rio-convergence/'



  'fiesta-island-vanlife-august-2019':
    name: 'Fiesta Island August Vanlife Gathering'
    id: '613cfea0-9dcb-11e9-bed5-893b7133de0e'
    location: {lat: 32.778860, lon: -117.218341}
    details: '''
Normal Time: 10:00am-4:00pm

KEEP RIGHT AT THE FORK!!!!

Potluck at noon

Other events TBD

Sunset “bond”-fire if you desire to stay longer with your new friends.

Fiesta Island closes at 10:00pm.

Absolutely NO GLASS and alcohol MUST be in a separate container.
'''
    startTime: new Date(2019, 7, 10, 10, 0, 0) # 10am PT
    endTime: new Date(2019, 7, 10, 22, 0, 0)
    address:
      locality: 'San Diego'
      administrativeArea: 'CA'
    prices:
      all: 0
    contact:
      website: 'https://sdcampervans.com/new-events/2019/8/10/fiesta-island-vanlife-gathering'



  'burning-man-2019':
    name: 'Burning Man'
    id: 'd5632fc0-9dcb-11e9-9e28-636118764a7e'
    location: {lat: 40.786119, lon: -119.206561}
    details: '''
Burning Man is not a festival! It’s a city wherein almost everything that happens is created entirely by its citizens, who are active participants in the experience.
'''
    startTime: new Date(2019, 7, 25, 0, 0, 0)
    endTime: new Date(2019, 8, 2, 0, 0, 0)
    address:
      locality: 'Black Rock City'
      administrativeArea: 'NV'
    prices:
      all: 470
    contact:
      website: 'https://burningman.org/'



  'adventure-van-expo-mt-hood-meadows-2019':
    name: 'Adventure Van Expo - Mt. Hood Meadows'
    id: 'd56af7f0-9dcb-11e9-8ae0-a61e52355c12'
    location: {lat: 45.331570, lon: -121.664878}
    details: '''
The show will feature built-out Mercedes Sprinters (mostly) 4x4 rigs, accessories, things buy for your van and more. Come out and meet the builders, network with Vanlifers, check out all kinds of cool workmanship and things maybe you’ve never seen, learn something new. There will be food and beer. Spend the weekend, use the camping area as your base to go play-the mountain bike park at the ski bowl will be open, ski up at Timberline. The Hood River Gorge is a half hour away.
'''
    startTime: new Date(2019, 6, 20, 0, 0, 0)
    endTime: new Date(2019, 6, 21, 0, 0, 0)
    address:
      locality: 'Mt. Hood Meadows'
      administrativeArea: 'OR'
    prices:
      all: 0
    contact:
      website: 'https://www.adventurevanexpo.com/mt-hood-meadows'



  'adventure-van-expo-mt-hood-meadows-2019':
    name: 'Adventure Van Expo - Mt. Hood Meadows'
    id: 'd56af7f0-9dcb-11e9-8ae0-a61e52355c12'
    location: {lat: 45.331570, lon: -121.664878}
    details: '''
The show will feature built-out Mercedes Sprinters (mostly) 4x4 rigs, accessories to view and buy for your rig or van, and more. Come out and meet the builders, network with vanlifers, check out all kinds of cool workmanship and things maybe you’ve never seen, learn something new.

There will be product demos and a section for van owners to park and network.

There will be food and beer. And a show in the Amphitheater 1 of the nights.
'''
    startTime: new Date(2019, 6, 20, 0, 0, 0)
    endTime: new Date(2019, 6, 21, 0, 0, 0)
    address:
      locality: 'Mt. Hood Meadows'
      administrativeArea: 'OR'
    prices:
      all: 0
    contact:
      website: 'https://www.adventurevanexpo.com/mt-hood-meadows'

module.exports = _.map events, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
