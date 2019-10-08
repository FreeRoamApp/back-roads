nodemailer = require 'nodemailer'
smtpTransport = require 'nodemailer-smtp-transport'
markdown = require('nodemailer-markdown').markdown
aws = require 'aws-sdk'
Promise = require 'bluebird'

JobCreateService = require './job_create'
User = require '../models/user'
config = require '../config'

aws.config.update
  # Necessary due to non-dns compliant bucket naming - e.g. cdn.wtf
  region: config.AWS.REGION
  accessKeyId: config.AWS.SES_ACCESS_KEY_ID
  secretAccessKey: config.AWS.SES_SECRET_ACCESS_KEY

SEND_EMAIL_TIMEOUT = 60 * 1000 # 60s

transporter = nodemailer.createTransport({
    SES: new aws.SES({
        apiVersion: '2010-12-01'
    })
    # sendingRate is handled by our own queue/rate limit
    # sendingRate: 10
})

transporter.use('compile', markdown({}))

class EmailService
  EMAILS:
    EVERYONE: 'Everyone <austin@freeroam.app>'

  # from, to optional. to overrides userId->email
  queueSend: (options) ->
    {from, to, userId, subject, text, markdown, skipUnsubscribe,
      waitForCompletion} = options
    JobCreateService.createJob {
      queueKey: 'SES'
      waitForCompletion: waitForCompletion
      job: {from, to, userId, subject, text, markdown, skipUnsubscribe}
      type: JobCreateService.JOB_TYPES.SES.SEND_EMAIL
      ttlMs: SEND_EMAIL_TIMEOUT
      priority: JobCreateService.PRIORITIES.NORMAL
    }


  # don't call this directly, use queueSend
  sendEmail: ({from, to, userId, subject, text, markdown, skipUnsubscribe}) ->
    from ?= 'FreeRoam <team@freeroam.app>'

    console.log 'email', userId, to

    (if userId
      User.getById userId
    else
      Promise.resolve null
    )
    .then (user) ->
      if user
        unsubscribeUrl = User.getEmailUnsubscribeLinkByUser user
      else
        unsubscribeUrl = null

      mailOptions = {
        from: from
        to: to or user.email
        subject: subject
        text: text
        markdown: markdown
      }

      if markdown and not skipUnsubscribe and unsubscribeUrl
        mailOptions.markdown = """
#{markdown}

---
<sub>[Unsubscribe](#{unsubscribeUrl})</sub>
"""
      if text and not skipUnsubscribe and unsubscribeUrl
        mailOptions.text = """
#{text}

---
Unsubscribe: #{unsubscribeUrl}
"""

      # if config.ENV is config.ENVS.DEV
      #   console.log JSON.stringify mailOptions
      #   return Promise.resolve(null)

      transporter.sendMail mailOptions

module.exports = new EmailService()
