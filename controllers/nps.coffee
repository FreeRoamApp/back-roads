_ = require 'lodash'
router = require 'exoid-router'

EmailService = require '../services/email'
config = require '../config'

class NpsCtrl
  create: ({score, comment} = {}, {user}) ->
    if comment
      EmailService.send {
        to: EmailService.EMAILS.EVERYONE
        subject: "FreeRoam NPS (#{score})"
        text: """
        #{user?.username}:

        #{comment}
        """
      }

module.exports = new NpsCtrl()
