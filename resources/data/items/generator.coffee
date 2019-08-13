# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'generator'
  id: '73de0e30-ba07-11e8-9fde-687163ee8e09'
  name: 'Generator'
  categories: ['boondocking']
  priority: 3
  why: "Solar is great, but if you want to run A/C, or have string of cloudy days, it's good to have a generator. You can even use just a generator without solar. A generator will charge your batteries and give you power off-grid."
  # what: ''
  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some']
  decisions: [
    {
      title: 'Inverter generator vs standard'
      text: """
This one isn't much of a decision, you should be getting an inverter generator. Normal, non-inverter generators are typically used in construction. They're far louder and produce less pure electricity, so they're not great for electronics. All the generators we list are inverter generators
"""
    }
    {
      title: 'How many watts?'
      text: """
Generators come in all sizes - typically anywhere from 1,000W (watts) all the way to 7,000W.

An RV A/C takes ~3,000W to start and 1,500 watts while running, but most other electronics will take 1,500 or less. ~2,000W is generally good for anything but A/C, but you'll need 3,000+ if you want A/C.

If you only need the generator to charge your batteries, and have an inverter that's powerful to run the electronics you need, you can get away with something as small as 1,000W to charge your batteries.

Higher wattage generators are going to be larger and heavier, so you'll need to factor that in as well. You can get two smaller (2,000W) generators and run them in parallel so each one is easier to move than a larger 4,000W

Generators usually list the "surge" watts, but you should be using the "rated" watts instead. Also factor in that generators don't work at 100% efficiency at high altitude. At 5,500 feet, they run at ~80% efficiency (meaning a 2,000W generator will provide 1,600W)
"""
    }
    {
      title: 'Dual fuel vs gas-only'
      text: """
Some generators can run off both gas and propane. Running on propane is less efficient and more expensive, but propane is something you'll usually have if you're in an RV. Sometimes it's nice to have the option, but most generators are gas-only.
"""
    }
    {
      title: 'Honda / Yamaha vs "The others"'
      text: """
The two brands people trust most, by far, are Honda and Yamaha, BUT they cost about double what the other brands cost. There are other good brands out there with good reviews, but on average, they are probably not as reliable. The question is, are they at least 50% as reliable? It depends on who you ask, but plenty of boondockers get by just fine with the other brands.
"""
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: '-sWJzM_Snmc', name: 'RV generators explained'}
  ]


products =
  "honda-eu2200i-inverter-generator":
    id: '19e197d0-bcb8-11e9-be8b-29cdae2025ea'
    name: 'Honda EU2200i (1800W running) Inverter Generator'
    priority: 2
    description: '''
Hands-down the most recommended generator you can get. They're reliable and quiet, at a cost (twice the price of some of the others here)
'''
    source: 'amazon'
    sourceId: 'B07R1HK2RL'
    reviewersLiked: ['Reliable', 'Lightweight', 'Very quiet']
    reviewersDisliked: ['Price']
    decisions: ['1800W', 'Gas', 'Honda']
    data:
      countryOfOrigin: 'Thailand'

  "westinghouse-igen2500-inverter-generator":
    id: '19ebf810-bcb8-11e9-ad61-557bc36d5ae5'
    name: 'Westinghouse iGen2500 (2200W running) Inverter Generator'
    description: '''
An affordable generator with more running watts than the Honda for about half the price. Not as well-built, but has good reviews on Amazon.
'''
    source: 'amazon'
    sourceId: 'B01MTGJGCN'
    reviewersLiked: ['Quiet', 'Lightweight', 'Cost-effective']
    reviewersDisliked: ['Some complaints of mistakes made by factory', 'Not as reliable as a Honda generator']
    decisions: ['2200W', 'Gas']
    data:
      countryOfOrigin: 'China'

  "champion-3400w-dual-fuel-inverter-generator":
    id: '2cda9e40-bcb8-11e9-a1fd-b570a7d2a41a'
    name: 'Champion 3100W (running) Dual Fuel Inverter Generator'
    priority: 1
    description: '''
A generator big enough to run a 15,000btu A/C and can run off of propane or gas. Champion has been making generators for a long time
'''
    source: 'amazon'
    sourceId: 'B01FAWMMEY'
    reviewersLiked: ['Electric start', 'Can use propane']
    reviewersDisliked: ['Had trouble running 15,000btu A/C on propane']
    decisions: ['3100W', 'Dual Fuel']

  "wen-1250w-inverter-generator":
    id: '2ce9b970-bcb8-11e9-bb4a-1f61bd2a3181'
    name: 'WEN 1000W (running) Inverter Generator'
    description: '''
  A no-frills small inverter generator that's good for recharging batteries. Smaller and lighter than most generators, but doesn't produce as much power
  '''
    source: 'amazon'
    sourceId: 'B074H5HGSX'
    reviewersLiked: ['Quiet', 'Small', 'Affordable', 'Easy to use']
    reviewersDisliked: ["Small percentage of users has reliability problems"]
    decisions: ['1000W', 'Gas']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
