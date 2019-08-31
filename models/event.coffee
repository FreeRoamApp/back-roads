_ = require 'lodash'
Promise = require 'bluebird'
uuid = require 'node-uuid'

PlaceBase = require './place_base'
cknex = require '../services/cknex'
elasticsearch = require '../services/elasticsearch'

scyllaFields =
  # common between all places
  slug: 'text' # eg: old-settlers-rv-park
  id: 'timeuuid'
  name: 'text'
  location: {type: 'map', subType: 'text', subType2: 'double'} # {lat, lon}
  details: 'text' # wikipedia style info. can be stylized with markdown
  thumbnailPrefix: 'text'
  startTime: 'timestamp'
  endTime: 'timestamp'
  address: 'json'
    # thoroughfare: 'text' # address
    # premise: 'text' # apt, suite, etc...
    # locality: 'text' # city / town
    # administrativeArea: 'text' # state / province / region. iso when avail
    # postal_code: 'text'
    # country: 'text' # 2 char iso
  # subType: 'text' # gathering / small meetup?
  contact: 'json' # json
    # phone
    # email
    # website
  # end common

  userId: 'uuid'
  prices: 'json' # json

class Event extends PlaceBase
  getScyllaTables: ->
    [
      {
        name: 'events_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['slug']
      }
      {
        name: 'events_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
    ]

  getElasticSearchIndices: ->
    [
      {
        name: 'events'
        mappings:
          # common between all places
          slug: {type: 'keyword'}
          name: {type: 'text'}
          location: {type: 'geo_point'}
          thumbnailPrefix: {type: 'keyword'}
          address: {type: 'object'}
          startTime: {type: 'date'}
          endTime: {type: 'date'}
          groupId: {type: 'text'}
          # subType: {type: 'keyword'}
          # end common
      }
    ]

  getAll: ({limit} = {}) =>
    limit ?= 30

    elasticsearch.search {
      index: @getElasticSearchIndices()[0].name
      type: @getElasticSearchIndices()[0].name
      size: limit
      sort: ['startTime']
    }
    .then ({hits}) ->
      _.map hits.hits, ({_id, _source}) ->
        _.defaults _source, {id: _id}

  defaultOutput: (event) ->
    unless event?
      return null

    event = super event
    _.defaults {type: 'event'}, event

  defaultESOutput: (event) ->
    event = _.defaults {
      type: 'event'
    }, _.pick event, ['id', 'slug', 'name', 'location']

module.exports = new Event()
