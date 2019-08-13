# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'grill'
  id: '045a7b20-bd76-11e9-b5db-503522e2a6bb'
  name: 'Grill'
  priority: 1
  categories: ['outdoors']
  why: 'Is it really camping if you don\'t grill something? In all seriousness, even if you\'re not a big fan of grilling, it can be easier to clean up, and sometimes your kitchen feels just a little too small...'
  what: ''


  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Traditional vs griddle'
      text: "A traditional grill has grates, so what you're cooking is over a flame. Griddle-style grills have a flat surface over the flame, so you can cook things like bacon, pancakes, etc..."
    }
    {
      title: 'Propane vs Charcoal'
      text: "Unless you really like how food tastes on charcoal grills, you'll probably want a propane grill. It'll be a whole lot easier to setup and cleanup. Typically you'll use the 1lb propane tanks you can find at any store, but you can also hook it up to an RV propane tank"
    }
    {
      title: 'Size'
      text: "Any grill you get for camping will probably be smaller than what you might have had at home, since you have to move it around often, but the sizes still vary. If you don't have much storage space, you're probably going to want a smaller grill"
    }
  ]
  videos: [
    {sourceType: 'youtube', sourceId: 'Kbp4LiOjXbI', name: 'Connecting grill to RV propane tank'}
  ]

products =
  "blackstone-griddle-grill":
    id: '9975bd70-bd7e-11e9-ba4b-7f69cee388ad'
    name: 'Blackstone Griddle'
    description: "An affordable, high quality griddle-type grill. These have become quite popular in the past few years due to that combination. They have 17\" and 22\" versions"
    source: 'amazon'
    sourceId: 'B0195MZHBK'
    decisions: ['Griddle', 'Propane', 'Small']
    videos: [
      {sourceType: 'youtube', sourceId: 'QIOB9AX66aA', timestamp: '2m16s', name: 'Blackstone griddle review'}
    ]

  "coleman-fold-n-go-grill":
    id: '998e9ca0-bd7e-11e9-94a9-2cee60baef1b'
    name: 'Coleman Fold N Go'
    description: "If you're short on storage space, this is a great grill - very compact and makes some tasty food (traps in the smoke well)"
    source: 'amazon'
    sourceId: 'B001RU04XK'
    decisions: ['Traditional', 'Propane', 'Small']
    videos: [
      {sourceType: 'youtube', sourceId: 'fzry-To2his', name: 'Coleman Fold N Go Review'}
    ]

  "weber-q1200-grill":
    id: '999a0e50-bd7e-11e9-9155-7cee4f06e8d1'
    name: 'Weber Q1200'
    description: "If you're familiar with grills, you're familiar with Weber, a high quality brand of grills. This one is no different - a great grill, albeit more costly than others. Has a handy thermometer built-in (which most others don't have)"
    source: 'amazon'
    sourceId: 'B00FGEHG6Q'
    decisions: ['Traditional', 'Propane', 'Large']
    videos: [
      {sourceType: 'youtube', sourceId: 'nkHE6C6Dyjo', name: 'Weber Q1200 Review'}
    ]

  "weber-go-anywhere-grill":
    id: '849d0fa0-bd80-11e9-a82f-1bb2e7497519'
    name: 'Weber Go-Anywhere Grill'
    description: "If you've got to have that charcoal taste, this is a quality portable grill"
    source: 'amazon'
    sourceId: 'B00004RALJ'
    decisions: ['Traditional', 'Charcoal', 'Medium']
    videos: [
      {sourceType: 'youtube', sourceId: 'a9kU8nEI1Is', name: 'Weber Go-Anywhere Review'}
    ]


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
