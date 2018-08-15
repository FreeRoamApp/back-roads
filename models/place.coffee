_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

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



tables = [
  {
    name: 'places_by_id'
    keyspace: 'free_roam'
    fields:
      id: 'text' # eg: old-settlers-rv-park
      name: 'text'
      location: {type: 'set', subType: 'double'} # coordinates
      thoroughfare: 'text' # address
      premise: 'text' # apt, suite, etc...
      locality: 'text' # city / town
      administrative_area: 'text' # state / province / region. iso when avail
      postal_code: 'text'
      country: 'text' # 2 char iso
    primaryKey:
      partitionKey: ['id']
  }
]

defaultPlace = (place) ->
  unless place?
    return null

  _.defaults place, {
  }

defaultPlaceOutput = (place) ->
  unless place?
    return null

  place

elasticSearchIndices = [
  {
    name: 'places'
    mappings:
      name: {type: 'text'}
      location: {type: 'geo_point'}
  }
]

class Place
  SCYLLA_TABLES: tables
  ELASTICSEARCH_INDICES: elasticSearchIndices

  batchUpsert: (places) =>
    Promise.map places, (place) =>
      @upsert place

  upsert: (place) ->
    place = defaultPlace place

    Promise.all [
      cknex().update 'places_by_id'
      .set _.omit place, ['id']
      .where 'id', '=', place.id
      .run()

      @index place
    ]

  index: (place) ->
    place.location = {lat: place.location[0], lon: place.location[1]}
    elasticsearch.index {
      index: 'places'
      type: 'places'
      id: place.id
      body: _.pick place, ['name', 'location']
    }

  search: ({query}) ->
    elasticsearch.search {
      index: 'places'
      type: 'places'
      body:
        query: query
        from : 0
        size : 250
    }
    .then ({hits}) ->
      _.map hits.hits, '_source'

  getById: (id) ->
    cknex().select '*'
    .from 'places_by_id'
    .where 'id', '=', id
    .run {isSingle: true}
    .then defaultItemOutput

  getAll: ({limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'places_by_id'
    .limit limit
    .run()
    .map defaultItemOutput

module.exports = new Place()
