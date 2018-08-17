Promise = require 'bluebird'
_ = require 'lodash'

Notification = require '../models/notification'
config = require '../config'

class NotificationCtrl
  getAll: ({}, {user}) ->
    Notification.getAllByUserUuid user.uuid, {limit: 20}


module.exports = new NotificationCtrl()
