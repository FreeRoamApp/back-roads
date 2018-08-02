Promise = require 'bluebird'
_ = require 'lodash'

Notification = require '../models/notification'
config = require '../config'

class NotificationCtrl
  getAll: ({}, {user}) ->
    Notification.getAllByUserId user.id, {limit: 20}


module.exports = new NotificationCtrl()
