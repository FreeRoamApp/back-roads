Amenity = require '../models/amenity'
Campground = require '../models/campground'
Coordinate = require '../models/coordinate'
Overnight = require '../models/overnight'

class PlacesService
  getByTypeAndId: (type, id, {userId} = {}) ->
    (if type is 'amenity'
      Amenity.getById id
    else if type is 'overnight'
      Overnight.getById id
    else if type is 'coordinate'
      Coordinate.getByUserIdAndId userId, id
    else
      Campground.getById id
    )

module.exports = new PlacesService()
