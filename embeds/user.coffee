UserKarma = require '../models/user_karma'

class UserEmbed
  karma: (user) ->
    UserKarma.getByUserId user.id

module.exports = new UserEmbed()
