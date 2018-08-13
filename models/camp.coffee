_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'

# main should be like yelp, kayak, etc...? search page. when typing, prepopulate: boondocking, rv park, walmart

# TODO: should be camps or locations? locations could have hiking, dump stations, etc...

# TODO: https://qbox.io/blog/tutorial-how-to-geolocation-elasticsearch

# locations_by_price - can't narrow down by location... don't do
# locations_by_latitude - narrow down to all within y distance of latitude, then client-side filter by longitude?

# probably should just use elastic search for all of it: https://www.elastic.co/blog/geo-location-and-search
# then get by the id in here

# price:
# features: true/false (has/doesn't)?
# type: (walmart, boondocking, etc...)

# probably will narrow down by region, then iterate over each to filter...
# camp: queryInfo: {
#   minPrice: 'free', maxPrice: 'free',  amps: ['none'], maxLength: 25,
# }
# camp: queryInfo: {
#   minPrice: '15', maxPrice: '45',  amps: [30, 50], maxLength: 25,
#   categories: ['']
# }



# tables = [
#   {
#     name: 'items_by_id'
#     keyspace: 'free_roam'
#     fields:
#       id: 'text' # eg: surge-protector
#       categories: 'text'
#       name: 'text'
#       why: 'text'
#       what: 'text'
#       videos: 'text' # json (array of video objects)
#     primaryKey:
#       partitionKey: ['id']
#   }
# ]
#
# defaultItem = (item) ->
#   unless item?
#     return null
#
#   item.categories = JSON.stringify item.categories
#   item.videos = JSON.stringify item.videos
#
#   _.defaults item, {
#   }
#
# defaultItemOutput = (item) ->
#   unless item?
#     return null
#
#   if item.videos
#     item.videos = try
#       JSON.parse item.videos
#     catch
#       {}
#
#   item
#
# class Item
#   SCYLLA_TABLES: tables
#
#   batchUpsert: (items) =>
#     Promise.map items, (item) =>
#       @upsert item
#
#   upsert: (item) ->
#     item = defaultItem item
#
#     Promise.all _.flatten [
#       cknex().update 'items_by_id'
#       .set _.omit item, ['id']
#       .where 'id', '=', item.id
#       .run()
#
#       _.map JSON.parse(item.categories), (category) ->
#         cknex().update 'items_by_category'
#         .set _.omit item, ['categories', 'id']
#         .where 'category', '=', category
#         .andWhere 'id', '=', item.id
#         .run()
#     ]
#
#   getById: (id) ->
#     cknex().select '*'
#     .from 'items_by_id'
#     .where 'id', '=', id
#     .run {isSingle: true}
#     .then defaultItemOutput
#
#   getFirstByCategory: (category) ->
#     cknex().select '*'
#     .from 'items_by_category'
#     .where 'category', '=', category
#     .run {isSingle: true}
#     .then defaultItemOutput
#
#   getAll: ({limit} = {}) ->
#     limit ?= 30
#
#     cknex().select '*'
#     .from 'items_by_id'
#     .limit limit
#     .run()
#     .map defaultItemOutput
#
#   getAllByCategory: (category, {limit} = {}) ->
#     limit ?= 30
#
#     cknex().select '*'
#     .from 'items_by_category'
#     .where 'category', '=', category
#     .limit limit
#     .run()
#     .map defaultItemOutput

# module.exports = new Item()
