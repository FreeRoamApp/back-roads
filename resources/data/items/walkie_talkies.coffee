# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'walkie-talkies'
  id: '7e7a9270-bfc7-11e9-8d74-d6d08d21f6f8'
  name: 'Walkie Talkies'
  priority: 2
  categories: ['tech']
  why: "Walkie talkies can come in handy in a lot of ways when camping. If you're towing an RV, they can be helpful for the spotter to communicate with the driver. If your spouse or kids are out and about, it can also be a good way of keeping in touch when you may not have cell signal"
  what: ''

  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Range'
      text: "Walkie talkies have a range of anywhere from a few miles up to 50 miles. These ratings are based on optimal conditions, so realistically you'll get less than half of that."
    }
    {
      title: 'Number of channels'
      text: "There are 22 total 2-way radio channels you can use. You'll want to switch to a channel with no one else on it, which typically isn't an issue, but some walkie talkies have more usable channels than others"
    }
    {
      title: 'Battery type'
      text: "Most walkie talkies come with rechargeable batteries, but some of the lower-end ones just use standard batteries like AA"
    }
    {
      title: 'Earpiece vs none'
      text: "Some walkie talkies will come with a headset for hands-free use, which can be nice to have if driving"
    }
  ]
  videos: [
  ]

products =
  "arcshell-two-way-radios":
    id: '7e948310-bfc7-11e9-9dc3-83ce18d4d52e'
    name: 'Arcshell Two-Way Radios'
    description: "These aren't a name-brand, but they have good reviews and are a good budget option if you want rechargeable batteries and a headset"
    source: 'amazon'
    sourceId: 'B072JJFVJG'
    decisions: ['5mi', '16 channels', 'Rechargeable', 'Headset']

  "midland-two-way-radios":
    id: '296dd080-bfd6-11e9-8119-912ffce54787'
    name: 'Midland Two-Way radios'
    description: "Good quality walkie talkies with more power (higher) range than most"
    source: 'amazon'
    sourceId: 'B001WMFYH4'
    decisions: ['36mi', '22 channels', 'Rechargeable', 'Headset']

  "motorola-t100-talkabout-radios":
    id: '298b4390-bfd6-11e9-b25c-fe92eec5c1be'
    name: 'Motorola T100 Talkabout Radios'
    description: "Good budget walkie talkies from a name brand. Barebones, but they'll do the job!"
    source: 'amazon'
    sourceId: 'B01DM7AESK'
    decisions: ['16mi', '22 channels']
    # videos: [
    #   {sourceType: 'youtube', sourceId: 'Twm82aoAEUQ', name: 'DJI Spark Review'}
    # ]


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
