Promise = require 'bluebird'
_ = require 'lodash'

Notification = require '../models/notification'
config = require '../config'

class NotificationCtrl
  getUnreadCount: ({}, {user}) ->
    Notification.getAllByUserId user.id, {limit: 20}
    .then (notifications) ->
      count = _.filter(notifications, {isRead: false}).length
      return count

  getAll: ({markRead}, {user}) ->
    Notification.getAllByUserId user.id, {limit: 20}
    .tap (notifications) ->
      Promise.map notifications, (notification) ->
        unless notification.isRead
          Notification.upsert _.defaults {isRead: true}, notification



module.exports = new NotificationCtrl()
