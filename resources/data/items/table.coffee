# coffeelint: disable=max_line_length,cyclomatic_complexity
_ = require 'lodash'

item =
  slug: 'outdoor-table'
  id: '5caccc50-bd81-11e9-8a51-0b24f2116280'
  name: 'Table'
  priority: 2
  categories: ['outdoors', 'starting-out']
  why: "You're going to be outside a lot, so it's nice to have a table, whether it's to work from, cook, or eat off of"
  what: ''

  filters:
    rigType: ['tent', 'car', 'van', 'motorhome', 'travelTrailer', 'fifthWheel']
    experience: ['none', 'little', 'some', 'lots']
    hookupPreference: ['none', 'some', 'all']

  decisions: [
    {
      title: 'Aluminum vs plastic and steel'
      text: "Aluminum tends to be the best material since it's rust-proof (and light-weight), and your table will probably be out in the rain every once in a while. Plastic doesn't rust either, but tends to be less durable and typically has steel legs. Steel is durable and cheap, but will rust over time."
    }
    {
      title: 'Plank-style vs folding vs solid top'
      text: "The tabletops of plank-style tables collapse to about the size of a camping chair, but they tend to be less stable. Solid-top (non-folding) tables tend to be the sturdiest, but take up a lot of space. Folding tables are a nice middle-ground."
    }
    {
      title: 'Size'
      text: "Sizes range from small side tables, to large tables for dining"
    }
  ]
  videos: [
    # {sourceType: 'youtube', sourceId: 'Kbp4LiOjXbI', name: 'Connecting grill to RV propane tank'}
  ]

products =
  "redcamp-aluminum-folding-table":
    id: '06f023b0-bd82-11e9-8707-a49b89db6990'
    name: 'REDCAMP Aluminum Folding Table'
    description: "A small, sturdy aluminum table with a plastic top. Folds for portability"
    source: 'amazon'
    sourceId: 'B07331DTM6'
    decisions: ['Aluminum', 'Folding', 'Small']

  "alps-mountaineering-camp-table":
    id: '998e9ca0-bd7e-11e9-94a9-2cee60baef1b'
    name: 'ALPS Mountaineering Camp Table'
    description: "This all-aluminum table is good for 2 people and folds to the size of a normal camp chair"
    source: 'amazon'
    sourceId: 'B001RU04XK'
    decisions: ['Aluminum','Plank-style', 'Medium']
    videos: [
      # {sourceType: 'youtube', sourceId: 'fzry-To2his', name: 'Coleman Fold N Go Review'}
    ]

  "lifetime-camping-table":
    id: 'cbd250e0-bd8c-11e9-b799-622d189d7785'
    name: 'Lifetime Camping Table'
    description: "A large table that folds in half for portability. The legs are powder-coated steel, so they *shouldn't* rust, but might over time, especially if the paint gets chipped / scratched"
    source: 'amazon'
    sourceId: 'B003YJPC2A'
    decisions: ['Plastic', 'Folding', 'Large']


module.exports = {item, products: _.map products, (product, slug) -> _.defaultsDeep product, {itemSlug: item.slug, filters: item.filters, slug}}
# coffeelint: enable=max_line_length,cyclomatic_complexity
