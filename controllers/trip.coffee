Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'
request = require 'request-promise'
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
  EmbedService.TYPES.TRIP.USER
]
extrasEmbed = [
  EmbedService.TYPES.TRIP.DESTINATIONS_INFO
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
        console.log 'tripp', trip
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

  getAll: ({}, {user}) =>
    @getAllByUserId {userId: user.id}, {user}

  getAllByUserId: ({userId}, {user}) ->
    prefix = CacheService.PREFIXES.TRIPS_GET_ALL_BY_USER_ID
    key = "#{prefix}:#{userId}"
    CacheService.preferCache key, ->
      Trip.getAllByUserId userId
      .map EmbedService.embed {embed: defaultEmbed}
      .map EmbedService.embed {embed: overviewEmbed}
    , {expireSeconds: ONE_DAY_SECONDS}
    .filter (trip) ->
      trip?.settings?.privacy isnt 'private' or
        "#{user.id}" is "#{trip.userId}" or user.username is 'austin'

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
      if trip?.settings?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}" and user.username isnt 'austin'
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
  TODO: https://github.com/mapbox/mapbox-navigation-android/issues/875
  either use mapmatching -> directions, or silent waypoints to generate
  directions that can be used by mapbox navigation sdk
  ###
  getRoutesByIdAndRouteId: (options, {user}) ->
    {id, routeId, waypoints, avoidHighways, useTruckRoute,
      isEditingRoute} = options

    Promise.all [
      Trip.getById id
      Trip.getRouteByTripIdAndRouteId id, routeId
    ]
    .then ([trip, route]) ->
      if trip?.settings?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'

      # TODO: startCheckIn, endCheckIn lat/lon, route both ways
      # get elevation for each route
      startCheckIn = _.find trip.destinations, {id: "#{route.startCheckInId}"}
      endCheckIn = _.find trip.destinations, {id: "#{route.endCheckInId}"}

      altSlug = RoutingService.generateRouteSlug {
        locations: [
          {lat: startCheckIn.lat, lon: startCheckIn.lon}
          {lat: endCheckIn.lat, lon: endCheckIn.lon}
        ]
        settings:
          waypoints: waypoints
          avoidHighways: avoidHighways
          costing: if useTruckRoute then 'truck' else 'auto'
      }

      Promise.all [
        if isEditingRoute
          # TODO: make an id for this, cache on server for a day or so
          RoutingService.getRouteByRouteSlug altSlug, {includeShape: true}
          .then (route) ->
            {routeSlug: altSlug, legs: [{route}]}

        route
        # RoutingService.getRoute(
        #   {
        #     locations: [
        #       {lat: startCheckIn.lat, lon: startCheckIn.lon}
        #       {lat: endCheckIn.lat, lon: endCheckIn.lon}
        #     ]
        #   }
        #   {
        #     trip, includeShape: true
        #   }
        # )

      ]
      .then (routes) ->
        routes = _.filter routes
        Promise.map routes, (route) ->
          time = _.sumBy route.legs, ({route}) -> route.time
          distance = _.sumBy route.legs, ({route}) -> route.distance

          points = _.flatten _.map route.legs, ({route}) ->
            polyline.decode route.shape, 6

          shape = polyline.encode points, 6

          poly = polyline.encode(
            RoutingService.distributedSample(
              RoutingService.distributedSampleByDistance(points, 1, 'mi')
              100
            )
          , 6)

          RoutingService.getElevationsFromPolyline poly
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

            {
              routeSlug: route.routeSlug
              shape
              elevations
              time
              distance
              elevationStats: {gained, lost, min, max}
            }

  setRouteByIdAndRouteId: (options, {user}) ->
    {id, routeId, waypoints, avoidHighways, useTruckRoute,
      isEditingRoute} = options

    Promise.all [
      Trip.getById id
      Trip.getRouteByTripIdAndRouteId id, routeId
    ]
    .then ([trip, route]) ->
      if trip?.settings?.privacy is 'private' and "#{user.id}" isnt "#{trip.userId}"
        router.throw status: 401, info: 'Unauthorized'

      # stops = _.defaults {"#{routeId}": []}, trip.stops
      stops = trip.stops # don't actually need to delete old stops, just reroute
      console.log 'set route'
      tripRoute = _.defaults {
        legs: false # force re-fetch w/ new settings
        settings:
          waypoints: waypoints
          avoidHighways: avoidHighways
          useTruckRoute: useTruckRoute
      }, route

      Trip.upsertStopsByTripAndTripRoute trip, tripRoute, stops

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

  _addManeueversToLegacyId: (id) ->
    console.log 'RESET TRIP MANEUVERS'
    # FIXME: remove in jan 2020. legacy routes didn't include maneuvers
    Trip.getById id
    .then EmbedService.embed {embed: [EmbedService.TYPES.TRIP.ROUTES]}
    .then (trip) ->
      Trip.resetRoutesByRoutesEmbeddedTrip trip

  # for native turn-by-turn
  ###
  This isn't always 100% accurate. Sometimes mapbox take a point near an exit
  and decides to take that exit, then get back on :/ Unsure how to get
  to be more accurate
  ###
  # this code is sort of similar to Trip_getRoute
  getMapboxDirectionsByIdAndRouteId: ({id, routeId, location}) =>
    Promise.all [
      Trip.getById id
      Trip.getRouteByTripIdAndRouteId id, routeId, {includeManeuevers: true}
    ]
    .tap ([trip, route]) =>
      # FIXME: rm jan 2020
      if _.some(route.legs, ({route}) -> route.shape and not route.maneuvers)
        @_addManeueversToLegacyId id
    .then ([trip, tripRoute]) ->
      tripRoute = Trip.embedTripRouteLegLocationsByTrip trip, tripRoute
      (if location?.lat
        # need to route through current location
        # TODO: these settings are set in a bunch of places, should keep it DRY
        settings = _.defaults tripRoute?.settings, trip?.settings
        settings =
          costing: if settings?.useTruckRoute then 'truck' else 'auto'
          avoidHighways: settings?.avoidHighways
          rigHeightInches: settings?.rigHeightInches
        RoutingService.determineStopIndexAndDetourTimeByTripRoute(
          tripRoute, location, {settings, getRoute: true}
        )
      else
        Promise.resolve null
      ).then ({index, route} = {}) ->
        # location index (already enroute)
        if index?
          console.log 'enroute at index', index
          # get rid of all stops before this one
          tripRoute.legs = tripRoute.legs.slice(index + 1)
          # use newly generated leg that goes through their location
          tripRoute.legs.unshift {route}

        allPoints = _.flatten _.map tripRoute.legs, ({route}) ->
          polyline.decode route.shape, 6
        console.log 'all', allPoints.length
        maxPoints = 25
        # console.log 'tripRoute', tripRoute
        # if we distribute only by count, they tend to be at curves
        # which are more likely to screw mapbox up
        # distance = _.sumBy tripRoute.legs, ({tripRoute}) -> tripRoute.distance
        # sampleDistance = Math.ceil(distance / maxPoints)
        # points = RoutingService.distributedSampleByDistance points, sampleDistance, 'km' #, {includeBearings: true}
        # points = RoutingService.distributedSample points, maxPoints

        # TODO: determine where point is along tripRoute and fit into there...
        # maybe use the addStop code?
        points = [_.first allPoints]


        # TODO: <= 25. choose maneuvers close to low clearances?
        points = points.concat _.flatten _.map tripRoute.legs, (leg) ->
          _.filter _.map leg.route.maneuvers, (maneuver) ->
            allPoints[maneuver.end_shape_index + 1]

        points = points.concat [_.last allPoints]


        points = RoutingService.distributedSample points, maxPoints

        points = _.map points, ([lat, lon]) -> [lon, lat]
        # bearings = _.map points, ({bearing}) ->
        #   if bearing
        #     [Math.round(bearing), 10]
        #   else
        #     ''
        # points = _.map points, ({point}) -> [point[1], point[0]]
        # console.log points
        # console.log '------------'
        # console.log points.length


        routeOptions =
          steps: true
          # waypoint_names: []
          waypoints: [0, points.length - 1].join ';' # FIXME stops
          # bearings: bearings.join ';'
          annotations: 'duration,congestion'
          language: 'en'
          overview: 'full'
          continue_straight: true
          roundabout_exits: true
          geometries: 'polyline6'
          voice_instructions: true
          banner_instructions: true
          voice_units: 'imperial'
          access_token: config.MAPBOX_ACCESS_TOKEN

        # console.log routeOptions
        # console.log "https://api.mapbox.com/directions/v5/mapbox/driving/#{points.join(';')}"
        # return


        # max 100 coords
        url = "https://api.mapbox.com/directions/v5/mapbox/driving/#{points.join(';')}"
        Promise.resolve request url, {
          json: true
          qs: routeOptions
        }
        .then (response) ->
          _.defaults {
            "voiceLocale": "en-US"
            routeOptions: _.defaults {
              baseUrl: 'https://api.mapbox.com'
              user: ''
              profile: "driving-traffic"
              waypoints: null # [0, 1] # FIXME: stops
              coordinates: [_.first(points), _.last(points)] # FIXME: stops, is it best to use all points from before?
              # coordinates: points
              uuid: response.uuid
            }, routeOptions
          }, response.routes[0]
        .tap ->
          console.log 'got'


  uploadImage: ({}, {user, file}) ->
    ImageService.uploadImageByUserIdAndFile(
      user.id, file, {folder: 'trips'}
    )

  getStatesGeoJson: ->
    statesGeoJson

module.exports = new TripCtrl()
