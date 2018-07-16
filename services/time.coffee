moment = require 'moment'

config = require '../config'

class TimeService
  getScaledTimeByTimeScale: (timeScale, time) ->
    time ?= moment()
    if timeScale is 'day'
      'DAY-' + time.format 'YYYY-MM-DD'
    else if timeScale is 'biweek'
      'BIWEEK-' + time.format('YYYY') + (parseInt(time.format 'YYYY-WW') / 2)
    else if timeScale is 'week'
      'WEEK-' + time.format 'YYYY-WW'
    else if timeScale is 'month'
      'MONTH-' + time.format 'YYYY-MM'
    else
      time.format time.format 'YYYY-MM-DD HH:mm'

  getPreviousTimeByTimeScale: (timeScale, time) ->
    time ?= moment()
    if timeScale is 'day'
      time.subtract 1, 'days'
      'DAY-' + time.format 'YYYY-MM-DD'
    else if timeScale is 'biweek'
      time.subtract 2, 'weeks'
      'BIWEEK-' + time.format('YYYY') + (parseInt(time.format 'YYYY-WW') / 2)
    else if timeScale is 'week'
      time.subtract 1, 'weeks'
      'WEEK-' + time.format 'YYYY-WW'
    else if timeScale is 'month'
      time.subtract 1, 'months'
      'MONTH-' + time.format 'YYYY-MM'
    else
      time.subtract 1, 'minutes'
      time.format time.format 'YYYY-MM-DD HH:mm'

module.exports = new TimeService()
