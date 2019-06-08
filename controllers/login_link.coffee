_ = require 'lodash'

LoginLink = require '../models/login_link'

class LoginLinkCtrl
  getByUserIdAndToken: ({userId, token}) ->
    LoginLink.getByUserIdAndToken userId, token

module.exports = new LoginLinkCtrl()
