UserKarma = require '../models/user_karma'

class UserEmbed
  karma: (user) ->
    if user.id
      UserKarma.getByUserId user.id

module.exports = new UserEmbed()
