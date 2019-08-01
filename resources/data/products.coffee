_ = require 'lodash'
fs = require 'fs'

config = require '../../config'

items = fs.readdirSync('./resources/data/items')

products = scyllaTables = _.filter _.flattenDeep _.map items, (itemFile) ->
  {item, products} = require('./items/' + itemFile)
  products

module.exports = products
