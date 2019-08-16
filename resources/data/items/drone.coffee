# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'drone'
  id: '11473bd0-bf0a-11e9-98fd-5924531285f5'
  name: 'Drone'
  priority: 3
  categories: ['tech']
  why: "Drones can be pretty awesome for camping to get aerial footage of the places you're exploring"
  what: 'These range from cheap ($70) to pricey ($2,000), meaning there are many decisions to make, unless you know for sure you want the cheapest one, or the highest quality one. With a complex product like a drone, videos tend to be the most informative, so be sure to watch the associated video for the drones you\'re interested in'

  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Camera quality'
      text: "Video quality for dones ranges from 720p to 4k. From worst to best it goes 720p, 1080p, 2K, 4K."
    }
    {
      title: 'Controller vs phone app'
      text: "Most drones come with a controller, AND let you use an app on your phone to control it (and view the live video feed). Some don't have a separate controller and the only way to fly is with the app.

  Apps for drones use your phone's wifi to communicate to and from your phone."
    }
    {
      title: 'Battery life (flight time)'
      text: "Drones typically will have anywhere from 10 minutes to about 30 minutes of flight time."
    }
    {
      title: 'Stability'
      text: "Since these things are flying through the air, dealing with movement and wind, any video you're taking can get shaky.

Of course, that has been solved by manufacturers and some drones will have electronic image stabalization, mechanical stabalization with a gimbal, or a combination of the two. If you want good stability, you'll want a drone with a gimbal
"
    }
    {
      title: 'Extra features'
      text: """The more expensive drones will come with some nifty features like:

- Auto takeoff
- Return to home
- Follow mode
- Orbit (circles around a point)
- GPS
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'xc5CjQl7vaM', name: 'Drone buying guide'}
    {sourceType: 'youtube', sourceId: 'sLfEyQcbVD0', name: 'How to fly a drone'}
  ]

products =
  "dji-mavic-2-pro":
    id: '112e83b0-bf0a-11e9-87c2-0ce849371bb8'
    name: 'DJI Mavic 2 Pro'
    description: "If money isn't an obstacle for you, this is the one. Incredible quality video, great stability, and loads of features"
    source: 'amazon'
    sourceId: 'B07GDC5X74'
    decisions: ['4K', 'Controller', '31min', 'Gimbal stabalization']
    videos: [
      {sourceType: 'youtube', sourceId: 'ilzxZCjKQTU', name: 'Mavic 2 Pro Review'}
    ]

  "dji-mavic-air":
    id: '1151c320-bf0a-11e9-abdc-567e50fc1a9e'
    name: 'DJI Mavic Air'
    description: ""
    source: 'amazon'
    sourceId: 'B078WQ9SN3'
    decisions: ['4k', 'Controller', '21min', 'Gimbal stabalization']
    videos: [
      {sourceType: 'youtube', sourceId: 'T6Gv07_bTiw', name: 'Mavic Air Review', timestamp: '33s'}
    ]

  "dji-spark":
    id: '7166f7b0-bf16-11e9-bfe1-c098c24f025b'
    name: 'DJI Spark'
    description: "If money isn't an obstacle for you, this is the one. Incredible quality video, great stability, and loads of features"
    source: 'amazon'
    sourceId: 'B071SKF6PS'
    decisions: ['1080P', 'Controller', '16min', 'Gimbal stabalization']
    videos: [
      {sourceType: 'youtube', sourceId: 'Twm82aoAEUQ', name: 'DJI Spark Review'}
    ]

  "tello-quadcopter":
    id: '71852e10-bf16-11e9-8643-594e1d180873'
    name: 'Tello Quadcopter'
    description: "If you're just getting started with drones, and want a quality, affordable beginner drone, this is it. Ok camera, Ok flying ability, but it works well for the price"
    source: 'amazon'
    sourceId: 'B07BDHJJTH'
    decisions: ['720p', 'Phone app', '13min', 'No stabilization']
    videos: [
      {sourceType: 'youtube', sourceId: 'Z8_c704o6JE', name: 'Tello Quadcopter Review'}
    ]


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
