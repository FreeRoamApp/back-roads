AWS = require 'aws-sdk'

config = require '../config'

AWS.config.update
  # Necessary due to non-dns compliant bucket naming - e.g. cdn.wtf
  region: config.AWS.REGION
  accessKeyId: config.AWS.ACCESS_KEY_ID
  secretAccessKey: config.AWS.SECRET_ACCESS_KEY

module.exports = AWS
