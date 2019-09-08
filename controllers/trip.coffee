Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'
polyline = require '@mapbox/polyline'
simplify = require 'simplify-path'

CheckIn = require '../models/check_in'
Trip = require '../models/trip'
TripFollower = require '../models/trip_follower'
CacheService = require '../services/cache'
EmbedService = require '../services/embed'
PlacesService = require '../services/places'
ImageService = require '../services/image'
RoutingService = require '../services/routing'
statesGeoJson = require '../resources/data/states.json'
config = require '../config'

defaultEmbed = [
  EmbedService.TYPES.TRIP.DESTINATIONS_INFO
  EmbedService.TYPES.TRIP.USER
  EmbedService.TYPES.TRIP.ROUTES
]
extrasEmbed = [
  EmbedService.TYPES.TRIP.ROUTES
]
overviewEmbed = [
  EmbedService.TYPES.TRIP.OVERVIEW
]

ONE_DAY_SECONDS = 3600 * 24

class TripCtrl
  upsert: (diff, {user, file}) =>
    diff = _.pick diff, [
      'checkInIds', 'id', 'imagePrefix', 'name'
      'thumbnailPrefix', 'settings'
    ]
    diff = _.defaults {userId: user.id}, diff
    (if diff.id
      Trip.getById diff.id
    else
      Promise.resolve null
    )
    .then (trip) =>
      if trip and "#{trip.userId}" isnt "#{user.id}"
        router.throw {status: 401, info: 'Unauthorized'}

      Trip.upsertByRow trip, diff
      .then (trip) =>
        if file
          console.log 'uploading file'
          @_uploadThumbnail trip.id, file
          .then (thumbnail) ->
            Trip.upsertByRow trip, {
              thumbnailPrefix: thumbnail.prefix
            }
        else
          trip

  _uploadThumbnail: (tripId, file) ->
    ImageService.uploadImageByUserIdAndFile(
      tripId, file, {folder: 'trips'}
    )

  deleteByRow: ({row}, {user}) ->
    Trip.getById row.id
    .then (trip) ->
      unless trip.userId is user.id
        router.throw {status: 401, info: 'Unauthorized'}

      Trip.deleteByRow trip

  getAll: ({}, {user}) ->
    prefix = CacheService.PREFIXES.TRIPS_GET_ALL_BY_USER_ID
    key = "#{prefix}:#{user.id}"
    CacheService.preferCache key, ->
      Trip.getAllByUserId user.id
      .map EmbedService.embed {embed: defaultEmbed}
      .map EmbedService.embed {embed: overviewEmbed}
    , {expireSeconds: ONE_DAY_SECONDS}

  getAllFollowingByUserId: ({userId}, {user}) ->
    # TODO: clear whenever trip is updated
    prefix = CacheService.PREFIXES.TRIPS_GET_ALL_FOLLOWING_BY_USER_ID
    key = "#{prefix}:#{user.id}"

    CacheService.preferCache key, ->
      TripFollower.getAllByUserId userId
      .map EmbedService.embed {embed: [EmbedService.TYPES.TRIP_FOLLOWER.TRIP]}
      .map (tripFollower) ->
        if tripFollower.trip
          prefix = CacheService.PREFIXES.TRIPS_FOLLOWING_TRIP_ID_CATEGORY
          category = "#{prefix}:#{tripFollower.trip.id}"
          CacheService.addCacheKeyToCategory key, category

        tripFollower.trip
      .then (trips) -> _.filter trips
      .map EmbedService.embed {embed: defaultEmbed}
      .map EmbedService.embed {embed: overviewEmbed}
      .map (trip) -> _.omit trip, ['checkIns', 'route']
    , {expireSeconds: ONE_DAY_SECONDS}

  getById: ({id}, {user}) ->
    console.log 'get', id
    # HACK: not sure where, but this is caled with 'null' when tooltip is opened
    # when adding new checkin
    if id is 'null'
      return null
    Trip.getById id
    .tap (trip) ->
      if trip?.settings?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'
    .then EmbedService.embed {embed: defaultEmbed}
    .then EmbedService.embed {embed: extrasEmbed}
    .then EmbedService.embed {embed: overviewEmbed}

  getRouteStopsByTripIdAndRouteIds: ({tripId, routeIds}, {user}) ->
    Trip.getById tripId
    .then (trip) ->
      if trip?.settings?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'

      stops = _.pick trip.stops, routeIds
      Promise.props _.mapValues stops, (routeStops, routeId) ->
        Promise.map routeStops, (stop) ->
          CheckIn.getById stop.id
          .then (checkIn) ->
            unless checkIn
              return
            PlacesService.getByTypeAndId checkIn.sourceType, checkIn.sourceId, {
              userId: trip.userId
            }
            .catch (err) -> null
            .then (place) ->
              checkIn.place = place
              checkIn

  ###
  FIXME FIXME: either allow route drag/drop, or use mapbox to find some alternate routes?
  problem with mapbox is avoiding low clearances...
  ###
  getRoutesByTripIdAndRouteId: ({tripId, routeId}, {user}) ->
    Promise.all [
      Trip.getById tripId
      Trip.getRouteByTripIdAndRouteId tripId, routeId
    ]
    .then ([trip, route]) ->
      if trip?.settings?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'

      # TODO: startCheckIn, endCheckIn lat/lon, route both ways
      # get elevation for each route
      startCheckIn = _.find trip.destinations, {id: "#{route.startCheckInId}"}
      endCheckIn = _.find trip.destinations, {id: "#{route.endCheckInId}"}
      Promise.all [
        RoutingService.getRoute({
          locations: [
            {lat: startCheckIn.lat, lon: startCheckIn.lon}
            {lat: endCheckIn.lat, lon: endCheckIn.lon}
          ]
        }, {trip, includeShape: true})

        # RoutingService.getRoute({
        #   locations: [
        #     {lat: startCheckIn.lat, lon: startCheckIn.lon}
        #     {lat: endCheckIn.lat, lon: endCheckIn.lon}
        #   ]
        # }, {includeShape: true, costing: 'truck'})
      ]
      .then (routes) ->
        Promise.map routes, (route) ->
          points = polyline.encode(
            RoutingService.distributedSample polyline.decode(route.shape), 100
          )
          RoutingService.getElevationsFromPolyline points
          .then (elevations) ->
            lastElevation = null
            gained = _.reduce elevations, (gained, [x, elevation]) ->
              if lastElevation? and elevation > lastElevation
                gained += elevation - lastElevation
              lastElevation = elevation
              gained
            , 0
            lastElevation = null
            lost = _.reduce elevations, (lost, [x, elevation]) ->
              if lastElevation? and elevation < lastElevation
                lost += lastElevation - elevation
              lastElevation = elevation
              lost
            , 0

            max = _.maxBy(elevations, ([x, elevation]) -> elevation)[1]
            min = _.minBy(elevations, ([x, elevation]) -> elevation)[1]
            _.defaults {
              elevations
              elevationStats: {gained, lost, min, max}
            }, route


  upsertStopByIdAndRouteId: ({id, routeId, checkIn}, {user}) =>
    Promise.all [
      Trip.getById id
      Trip.getRouteByTripIdAndRouteId id, routeId
      PlacesService.getByTypeAndId checkIn.sourceType, checkIn.sourceId, {
        userId: user.id
      }
    ]
    .then ([trip, tripRoute, place]) ->
      unless trip.userId is user.id
        router.throw {status: 401, info: 'Unauthorized'}

      Trip.upsertStopByTripAndTripRoute(
        trip, tripRoute, checkIn, place.location
      )

  deleteStopByIdAndRouteId: ({id, routeId, stopId}, {user}) ->
    Promise.all [
      Trip.getById id
      Trip.getRouteByTripIdAndRouteId id, routeId
    ]
    .then ([trip, tripRoute]) ->
      unless trip.userId is user.id
        router.throw {status: 401, info: 'Unauthorized'}

      Trip.deleteStopByTripAndTripRoute trip, tripRoute, stopId

  deleteDestinationById: ({id, destinationId}, {user}) ->
    Trip.getById id
    .then EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTES]}
    .then (trip) ->
      unless trip.userId is user.id
        router.throw {status: 401, info: 'Unauthorized'}
      Trip.deleteDestinationByRoutesEmbeddedTrip trip, destinationId

  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'trips'}
    )

  getStatesGeoJson: ->
    statesGeoJson

module.exports = new TripCtrl()
