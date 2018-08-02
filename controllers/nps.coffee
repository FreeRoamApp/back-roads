_ = require 'lodash'
router = require 'exoid-router'
googleTranslate = require 'google-translate'

EmailService = require '../services/email'
config = require '../config'

googleTranslate = googleTranslate config.GOOGLE_API_KEY_MYSTIC

class NpsCtrl
  create: ({score, comment} = {}, {user}) ->
    if comment
      googleTranslate.translate comment, 'en', (err, translation) ->
        EmailService.send {
          to: EmailService.EMAILS.EVERYONE
          subject: "Free Raom NPS (#{score})"
          text: """
          #{user?.username}:

          #{translation?.translatedText}

          #{translation?.detectedSourceLanguage}

          #{comment}
          """
        }

module.exports = new NpsCtrl()
