_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

Trip = require '../models/trip'
TripFollower = require '../models/trip_follower'
User = require '../models/user'
Subscription = require '../models/subscription'
EmbedService = require '../services/embed'
PushNotificationService = require '../services/push_notification'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.TRIP_FOLLOWER.TRIP]

class TripFollowerCtrl
  getAllByUserId: ({userId}, {user}) ->
    TripFollower.getAllByUserId userId
    .map EmbedService.embed {embed: defaultEmbed}

  upsertByTripId: ({tripId}, {user}) ->
    Promise.all [
      Trip.getById tripId
      TripFollower.getByUserIdAndTripId user.id, tripId
    ]
    .then ([trip, tripFollower]) ->
      unless tripFollower
        TripFollower.upsert {tripId, userId: user.id}
        .then ->
          User.getById trip.userId
          .then (tripCreatorUser) ->
            PushNotificationService.send tripCreatorUser, {
              titleObj:
                key: "newTripFollower.title"
              type: Subscription.TYPES.SOCIAL
              textObj:
                key: "newTripFollower.text"
                replacements:
                  name: User.getDisplayName(user)
                  tripName: trip.name
              data:
                path:
                  key: 'social'
            }
          .catch -> null

  deleteByRow: (row, {user}) ->
    unless row.userId is user.id
      router.throw {
        info: 'Unauthorized'
        status: 401
      }
    TripFollower.deleteByRow row


module.exports = new TripFollowerCtrl()
