AWS = require 'aws-sdk'

config = require '../config'

AWS.config.update
  region: config.AWS.REGION
  accessKeyId: config.AWS.ACCESS_KEY_ID
  secretAccessKey: config.AWS.SECRET_ACCESS_KEY

module.exports = AWS
