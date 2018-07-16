_ = require 'lodash'
fs = require 'fs'
Promise = require 'bluebird'

Page = require '../'
Player = require '../../../models/player'
DynamicImage = require '../../../models/dynamic_image'
FortniteStats = require '../../components/fortnite_stats'
s = require '../../components/s'
config = require '../../../config'

PATH = './dynamic_images/images'

IMAGE_KEY = 'forniteStats'

module.exports = class FortniteStatsPage extends Page
  constructor: ({req, res} = {}) ->
    @query = req.query
    @playerId = req.params.playerId
    @language = req.params.language or 'en'

    @$component = new FortniteStats()

  renderHead: -> ''

  setup: =>
    Player.getByPlayerIdAndGameKey @playerId, 'fortnite'
    .then (player) =>
      unless player
        return {}
      platform = @playerId.split(':')?[0] or 'pc'
      backgroundPath = PATH + '/fortnite/stats_background.png'
      platformIconPath = PATH + "/fortnite/platform_icons/#{platform}.png"

      Promise.all [
        Promise.promisify(fs.readFile) backgroundPath
        Promise.promisify(fs.readFile) platformIconPath
      ]
      .then ([background, platformIcon]) =>
        images = {
          background: new Buffer(background).toString('base64')
          platformIcon: new Buffer(platformIcon).toString('base64')
        }

        {player, @query, images, width: 573, height: 300, @language}
