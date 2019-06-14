UserKarma = require '../models/user_karma'
UserData = require '../models/user_data'

class UserEmbed
  data: (user) ->
    UserData.getByUserId user.id

  karma: (user) ->
    UserKarma.getByUserId user.id

module.exports = new UserEmbed()
