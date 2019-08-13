Promise = require 'bluebird'
_ = require 'lodash'

Category = require '../models/category'
UserData = require '../models/user_data'
UserRig = require '../models/user_rig'
EmbedService = require '../services/embed'
config = require '../config'

defaultEmbed = [EmbedService.TYPES.CATEGORY.ITEM_NAMES]

###
rig: tent, car, van, motorhome, travelTrailer, fifthWheel
experience: none, little, some, lots
hookupPreference: none, some, all
###

class CategoryCtrl
  getAll: ({}, {user}) ->
    Promise.all [
      UserData.getByUserId user.id
      UserRig.getByUserId user.id
    ]
    .then ([userData, userRig]) ->
      Category.getAll {
        rig: userRig?.type
        experience: userData?.experience
        hookupPreference: userData?.hookupPreference
      }
    .map EmbedService.embed {embed: defaultEmbed}


module.exports = new CategoryCtrl()
