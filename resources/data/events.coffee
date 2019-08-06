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
    startTime: new Date(2019, 6, 11, 12, 0, 0)
    endTime: new Date(2019, 6, 14, 12, 0, 0)
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
    startTime: new Date(2019, 6, 12, 12, 0, 0)
    endTime: new Date(2019, 6, 14, 12, 0, 0)
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
    startTime: new Date(2019, 6, 18, 12, 0, 0)
    endTime: new Date(2019, 6, 22, 12, 0, 0)
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
    startTime: new Date(2019, 7, 2, 12, 0, 0)
    endTime: new Date(2019, 7, 4, 12, 0, 0)
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
    startTime: new Date(2019, 7, 25, 12, 0, 0)
    endTime: new Date(2019, 8, 2, 12, 0, 0)
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
    startTime: new Date(2019, 6, 20, 12, 0, 0)
    endTime: new Date(2019, 6, 21, 12, 0, 0)
    address:
      locality: 'Mt. Hood Meadows'
      administrativeArea: 'OR'
    prices:
      all: 0
    contact:
      website: 'https://www.adventurevanexpo.com/mt-hood-meadows'



  'adventure-van-expo-dillon-2019':
    name: 'Adventure Van Expo - Dillon'
    id: 'cbcee290-9ddc-11e9-abbd-e15655dee6a3'
    location: {lat: 39.626123, lon: -106.047088}
    details: '''
The show will feature built-out Mercedes Sprinters (mostly) 4x4 rigs, accessories to view and buy for your rig or van, and more. Come out and meet the builders, network with vanlifers, check out all kinds of cool workmanship and things maybe you’ve never seen, learn something new.

There will be product demos and a section for van owners to park and network.

There will be food and beer. And a show in the Amphitheater 1 of the nights.
'''
    startTime: new Date(2019, 7, 10, 12, 0, 0)
    endTime: new Date(2019, 7, 11, 12, 0, 0)
    address:
      locality: 'Dillon'
      administrativeArea: 'CO'
    prices:
      all: 0
    contact:
      website: 'https://www.adventurevanexpo.com/dillon-colorado'



  'adventure-van-expo-lake-tahoe-2019':
    name: 'Adventure Van Expo - Lake Tahoe'
    id: 'cbdb3ea0-9ddc-11e9-a3e9-06b1594c498f'
    location: {lat: 39.085594, lon: -120.160469}
    details: '''
Come check out the incredible van builds, open house vans, vans, and more vans!  But not just vans-4 Wheel Camper will be returning this year, with 3 rigs this time, as will Aluminess, Sportsmobile,  Allrad4x4, Roambuilt, and more….there will be solar talks, demonstrations food and beer. We will be at the Homewood Mountain Ski resort on Tahoe’s West shore. Same place as last year.
'''
    startTime: new Date(2019, 8, 7, 12, 0, 0)
    endTime: new Date(2019, 8, 8, 12, 0, 0)
    address:
      locality: 'Lake Tahoe'
      administrativeArea: 'CA'
    prices:
      all: 0
    contact:
      website: 'https://www.adventurevanexpo.com/lake-tahoe'



  'the-oregon-love-2019':
    name: 'The Oregon Love'
    id: 'ad7032b0-9ddf-11e9-a938-9794557217c5'
    location: {lat: 44.408770, lon: -121.871370}
    details: '''
The Oregon Love is distinctly tailored for VW Bus, Sprinter, Eurovan, Syncro, Truck Camper, Compact RV, Jeep, Customs, MOG and road-life / outdoor enthusiasts. Join us for a full weekend of camping, festivities, live music, themed activities and food and beverage offerings!
'''
    startTime: new Date(2019, 8, 13, 12, 0, 0)
    endTime: new Date(2019, 8, 15, 12, 0, 0)
    address:
      locality: 'Sisters'
      administrativeArea: 'OR'
    prices:
      all: 50
    contact:
      website: 'https://www.theoregonlove.com/'



  'descend-on-bend-2019':
    name: 'Descend on Bend'
    id: 'ad7f4de0-9ddf-11e9-b992-7d2a4f341f81'
    location: {lat: 43.393437, lon: -121.212213}
    details: '''
Private land access fee for five days and four nights of glorious camping 1/4 mile from the hole-in-the-ground, in the Oregon outback
'''
    startTime: new Date(2019, 7, 29, 12, 0, 0)
    endTime: new Date(2019, 8, 2, 12, 0, 0)
    address:
      locality: 'La Pine'
      administrativeArea: 'OR'
    prices:
      all: 99
    contact:
      website: 'https://www.descendonbend.com/'



  'taos-vanlife-gathering-2019':
    name: 'Taos Vanlife Gathering'
    id: '890b11f0-9de0-11e9-9d6f-9e3199a67f38'
    location: {lat: 39.376966, lon: -106.997352}
    details: '''
Vanlife Diaries & Idle Theory Bus present:

Join us for a weekend-long campout in the high desert mesa of Hotel Luna Mystica, a private venue with plenty of stars and space. Under the open sky, we’ll enjoy workshops and music, community and natural beauty.

This weekend is a welcoming, friendly space where vanlifers can gather to share, learn, and deepen our community. Today, much of our interaction happens online, but this weekend in Taos, we’ll circle our modern-day covered wagons to share our skills and stories face-to-face, while doing what we love in the outdoors—and checking out each other’s rigs, of course!
'''
    startTime: new Date(2019, 7, 16, 12, 0, 0)
    endTime: new Date(2019, 7, 18, 12, 0, 0)
    address:
      locality: 'Taos'
      administrativeArea: 'NM'
    prices:
      all: 50
    contact:
      website: 'https://www.vanlife.com.au/vanlifegatherings/taos'



  'new-orleans-vanlife-gathering-2019':
    name: 'New Orleans Vanlife Gathering'
    id: 'e9d36ae0-9de1-11e9-9a42-0075d57e1d09'
    location: {lat: 30.905168, lon: -90.304675}
    details: '''
Vanlife Diaries & Irie to Aurora present:

This is a three-day, two-night campout at the beautiful Mt. Hermon Surf Club in Mt. Hermon, Louisiana. It includes some amazing activities: LIVE MUSIC, YOGA, WORKSHOPS, VAN TOURS, POTLUCK DINNER, RAFFLE, COMMUNITY-LED DISCUSSIONS. A portion of ticket sales will be donated to the Healthy Gulf - formerly Gulf Restoration Network.

VANLIFE IS NOT A VEHICLE, IT’S A STATE OF MIND. So you don’t need a van to attend. Bring what you got: tent-lifin’, bike packin’, RV’n, car campin’, skoolie livin’, ALL ARE WELCOME. As long as you can camp off-grid (there will be no hookups and generators are NOT allowed). If you’re curious about vanlife, this is a great opportunity to tour some rigs and get inspired. The only requirement for this event is that you have an open mind, enjoy alternative ways of living, and want to meet some interesting people.

This is a LEAVE NO TRACE EVENT. There will be no trash cans on site, so PACK-IT-IN, PACK-IT-OUT. We’ll also be playing a fun little game: cleanest campsite wins a prize!

Bathrooms on site. Off-grid electric setups are welcome, but NO GENERATORS PLEASE. There is NO POTABLE WATER on site. Please bring enough water and food for the weekend. Pack it in, pack it out.
'''
    startTime: new Date(2019, 9, 18, 12, 0, 0)
    endTime: new Date(2019, 9, 20, 12, 0, 0)
    address:
      locality: 'Mt Hermon'
      administrativeArea: 'LA'
    prices:
      all: 50
    contact:
      website: 'https://www.vanlife.com.au/vanlifegatherings/new-orleans'



  'ashville-van-life-rally-2019':
    name: 'Ashville Van Life Rally'
    id: 'd1686400-9de2-11e9-901c-aa099e9aa548'
    location: {lat: 35.424150, lon: -82.495552}
    details: '''
Join us for the 5th Annual Asheville Van Life Rally, a celebration of the vanlife community and culture, hosted in the beautiful mountains of Western North Carolina, the Southeastern USA's home to outdoor adventure, as well as great are, beer, music, food, and people.

This is an opportunity to bring your vehicle and circle up with fellow vanlifers for connection, conversation, and celebration for this entire weekend of van life community-building! Be sure to secure a spot for your vehicle for this camping festival on 65 acres of beautiful land located just 20 minutes from downtown Asheville!'''
    startTime: new Date(2019, 8, 20, 12, 0, 0)
    endTime: new Date(2019, 8, 22, 12, 0, 0)
    address:
      locality: 'Fletcher'
      administrativeArea: 'NC'
    prices:
      all: 25
    contact:
      website: 'https://www.ashevillevanlife.com/'



  'el-campo-van-gathering-2019':
    name: 'El Campo Van Gathering'
    id: '9d544570-9de8-11e9-ad47-67aa8a65e510'
    location: {lat: 46.334221, lon: -71.15231}
    details: '''
Our major end of the season van gathering is back for a 4th edition and will happen once again at the Domaine Du Radar near Quebec City. Over 200 camper vans and great rigs, giveaways, cool brands on site, live music and a huge bonfire.

Gathering of vans (max length: 22 feet except exception) and music organized by Go-Van at Domaine du Radar. There will also be room available for car camping, tents, or vans! Domaine du Radar welcomes us for a 4th year to celebrate vanlife and share our best road trip stories of the summer. All owners of vans are invited to camp at the foot of the mountain for a weekend filled with beautiful encounters, outdoor activities and music.
'''
    startTime: new Date(2019, 8, 13, 12, 0, 0)
    endTime: new Date(2019, 8, 15, 12, 0, 0)
    address:
      locality: 'Saint-Sylvestre'
      administrativeArea: 'QC'
    prices:
      all: 87
    contact:
      website: 'https://go-van.com/the-events/el-campo-van-gathering-east/'



  'nomad-collab-colorado-2019':
    name: 'Nomad Collab Colorado Meetup'
    id: 'ed68e400-9f5d-11e9-8c11-f16d386f3dd8'
    location: {lat: 39.114853, lon: -108.329447}
    details: '''
Mountain biking, hiking the national monument and wine tasting with likeminded folks that want to make this lifestyle sustainable and not just a short chapter.

Nomad Collab is a community focused on helping couples build a lifestyle that allows them to live, work and adventure anywhere.

This event is free to attend, but to stay in the RV resort (Palisade Basecamp) costs $49 - $64/night
'''
    startTime: new Date(2019, 6, 12, 12, 0, 0)
    endTime: new Date(2019, 6, 14, 12, 0, 0)
    address:
      locality: 'Palisade'
      administrativeArea: 'CO'
    prices:
      all: 0
    contact:
      website: 'https://nomadcollab.com/'


  'adventure-van-meetup-2019':
    name: 'Aventure Van Meetup'
    id: '165bf060-b70e-11e9-844b-fbb64903225c'
    location: {lat: 39.782255, lon: -105.233578}
    details: '''
Calling all #vanlife purveyors and fans! It’s time for the 3rd Annual Powder7 Adventure Van Meetup.

Note: if you want to bring a rig, RSVP to Matty (mattm@powder7.com) or on this page by 9/1.

Here are the details on this year's event:
When: Saturday September 7, 9-11 a.m.
Where: Powder7, 880 Brickyard Circle, Golden, CO
What: A classic adventure rig meetup with coffee and donuts, stories from the open road, and a variety of rigs (last year, we saw a wizened Westy, a new-age 4WD Sprinter, and everything in between...)
'''
    startTime: new Date(2019, 8, 7, 8, 0, 0) # 9am MT
    endTime: new Date(2019, 8, 7, 10, 0, 0) # 11am mt
    address:
      locality: 'Golden'
      administrativeArea: 'CO'
    prices:
      all: 0
    contact:
      website: 'https://www.facebook.com/events/213498472931922/'


module.exports = _.map events, (value, slug) -> _.defaults {slug}, value
# coffeelint: enable=max_line_length,cyclomatic_complexity
