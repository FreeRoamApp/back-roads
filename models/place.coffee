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

# searching done in elasticsearch

tables = [
  {
    name: 'places_by_slug'
    keyspace: 'free_roam'
    fields:
      slug: 'text' # eg: old-settlers-rv-park
      id: 'timeuuid'
      name: 'text'

      details: 'text' # wikipedia style info. can be stylized with markdown
      drivingInstructions: 'text'

      location: {type: 'set', subType: 'double'} # coordinates
      siteCount: 'text' # json: {"maxSize(var)": count}, eg {50: 5, 40: 20} means 5 spots for 40-50ft, 20 spots for 0-40 ft. use unknown for size if unknown
      distanceTo: 'text' # json {groceries: 25, walmart: 10} all in miles

      # 0 my prius could get there, 5 need a truck, 10 need 4x4 high clearance van
      roadDifficulty: 'int'

      # 0 private spot, closest human 100yd+ away, 5 can see others, > 50 ft, 10 sardines
      crowdLevel: 'text' # json {winter: 2, spring: 5, summer: 10, fall: 5}

      # 0 silence, 5 occassional train / some road noise, 10 constant trains, highway noise
      noiseLevel: 'text' # json {day: 3, night: 0}

      # 0 no shade, 5 shade if you want it, 10 all shade
      shadeLevel: 'int'

      # 0 you might get murdered, 10 no worries at all
      safetyLevel: 'int'

      cellSignal: 'text' # json {verizon: {signal: 7, type: '4g'}, att: {signal: 3, type: '3g'}} 0-10 signal
      maxDays: 'int'
      hasFreshWater: 'boolean'
      hasSewage: 'boolean'
      has30Amp: 'boolean'
      has50Amp: 'boolean'
      minPrice: 'int'
      maxPrice: 'int'
      maxLength: 'int'
      videos: 'text' # json
      address: 'text' # json:
        # thoroughfare: 'text' # address
        # premise: 'text' # apt, suite, etc...
        # locality: 'text' # city / town
        # administrative_area: 'text' # state / province / region. iso when avail
        # postal_code: 'text'
        # country: 'text' # 2 char iso
    primaryKey:
      partitionKey: ['slug']
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
      roadDifficulty: {type: 'integer'}
      crowdLevel: {type: 'object'}
      noiseLevel: {type: 'object'}
      shadeLevel: {type: 'integer'}
      safetyLevel: {type: 'integer'}
      cellSignal: {type: 'object'}
      maxDays: {type: 'integer'}
      hasFreshWater: {type: 'boolean'}
      hasSewage: {type: 'boolean'}
      has30Amp: {type: 'boolean'}
      has50Amp: {type: 'boolean'}
      minPrice: {type: 'integer'}
      maxPrice: {type: 'integer'}
      maxLength: {type: 'integer'}
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
      # FIXME
      # cknex().update 'places_by_slug'
      # .set _.omit place, ['slug']
      # .where 'slug', '=', place.slug
      # .run()

      @index place
    ]

  index: (place) ->
    place.location = {lat: place.location[0], lon: place.location[1]}
    elasticsearch.index {
      index: 'places'
      type: 'places'
      id: place.slug
      body: _.pick place, _.keys elasticSearchIndices[0].mappings
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
      _.map hits.hits, ({_id, _source}) ->
        {slug: _id, name: _source.name, location: _source.location}

  getBySlug: (slug) ->
    cknex().select '*'
    .from 'places_by_slug'
    .where 'slug', '=', slug
    .run {isSingle: true}
    .then defaultPlaceOutput

  getAll: ({limit} = {}) ->
    limit ?= 30

    cknex().select '*'
    .from 'places_by_slug'
    .limit limit
    .run()
    .map defaultPlaceOutput

module.exports = new Place()
