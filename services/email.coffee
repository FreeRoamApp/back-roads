nodemailer = require 'nodemailer'
aws = require 'aws-sdk'
Promise = require 'bluebird'
log = require 'loga'

JobCreateService = require './job_create'
config = require '../config'

aws.config.update
  # Necessary due to non-dns compliant bucket naming - e.g. cdn.wtf
  region: config.AWS.REGION
  accessKeyId: config.AWS.SES_ACCESS_KEY_ID
  secretAccessKey: config.AWS.SES_SECRET_ACCESS_KEY

FROM_EMAIL = 'FreeRoam <austin@freeroam.app>'
SEND_EMAIL_TIMEOUT = 60 * 1000 # 60s

transporter = nodemailer.createTransport({
    SES: new aws.SES({
        apiVersion: '2010-12-01'
    })
    # sendingRate is handled by our own queue/rate limit
    # sendingRate: 10
})

class EmailService
  EMAILS:
    EVERYONE: 'Everyone <austin@freeroam.app>'

  queueSend: ({to, subject, text}) ->
    JobCreateService.createJob {
      queueKey: 'SES'
      job: {to, subject, text}
      type: JobCreateService.JOB_TYPES.SES.SEND_EMAIL
      ttlMs: SEND_EMAIL_TIMEOUT
      priority: JobCreateService.PRIORITIES.NORMAL
    }


  # don't call this directly, use queueSend
  sendEmail: ({to, subject, text}) ->
    # if config.ENV is config.ENVS.TEST
    #   log.info "[TEST] Sending email to #{to}, subject:", subject
    #   return Promise.resolve(null)
    #
    # if config.ENV is config.ENVS.DEV
    #   log.info "[DEV] Sending email to #{to} ops: ", subject, text
    #   return Promise.resolve(null)
    #
    # if config.IS_STAGING
    #   log.info "[STAGING] Sending email to #{to} ops: ", subject, text
    #   return Promise.resolve(null)

    transporter.sendMail {
      from: 'FreeRoam <austin@freeroam.app>'
      to: to
      subject: subject
      text: text
      # html: html
    }

module.exports = new EmailService()
