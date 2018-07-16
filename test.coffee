config = require './config'
request = require 'request-promise'
Promise = require 'bluebird'

# TODO: player fetch timeout when doing multiple
console.log 'process', "#{config.CR_API_URL}/players/PCV8"
Promise.all [
  request "#{config.CR_API_URL}/players/PCV8", {json: true}
  request "#{config.CR_API_URL}/players/L8VQJC82", {json: true}
  request "#{config.CR_API_URL}/players/22CJ9CQC0", {json: true}
  request "#{config.CR_API_URL}/players/L8VQJC82", {json: true}
  request "#{config.CR_API_URL}/players/22CJ9CQC0", {json: true}
  request "#{config.CR_API_URL}/players/PCV8", {json: true}
]
.then ([a, b, c, d, e, f]) ->
  console.log a?[0]?.tag#length, a?[0]?[0]?.id
  console.log b?[0]?.tag#length, b?[0]?[0]?.id
  console.log c?[0]?.tag#length, c?[0]?[0]?.id
  console.log d?[0]?.tag#length, d?[0]?[0]?.id
  console.log e?[0]?.tag#length, e?[0]?[0]?.id
  console.log f?[0]?.tag#length, f?[0]?[0]?.id
return
