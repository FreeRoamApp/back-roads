Promise = require 'bluebird'
_ = require 'lodash'

Campground = require '../models/campground'
Amenity = require '../models/amenity'
PlaceBaseCtrl = require './place_base'

class CampgroundCtrl extends PlaceBaseCtrl
  type: 'campground'
  Model: Campground

  # TODO: heavily cache this
  getAmenityBoundsById: ({id}) ->
    # get closest dump, water, groceries
    Campground.getById id
    .then (campground) ->
      Amenity.search {
        query:
          bool:
            filter: [
              {
                geo_bounding_box:
                  location:
                    top_left:
                      lat: campground.location.lat + 5
                      lon: campground.location.lon - 5 # TODO: probably less than 5
                    bottom_right:
                      lat: campground.location.lat - 5
                      lon: campground.location.lon + 5
              }
            ]
        sort: [
          _geo_distance:
            location:
              lat: campground.location.lat
              lon: campground.location.lon
            order: 'asc'
            unit: 'km'
            distance_type: 'plane'
        ]
      }
      .then (amenities) ->
        dump = _.find amenities, ({amenities}) ->
          amenities.indexOf('dump') isnt -1
        water = _.find amenities, ({amenities}) ->
          amenities.indexOf('water') isnt -1
        groceries = _.find amenities, ({amenities}) ->
          amenities.indexOf('groceries') isnt -1

        place = {
          location: campground.location
        }
        importantAmenities = _.filter [place, dump, water, groceries]
        minX = _.minBy importantAmenities, ({location}) -> location.lon
        minY = _.minBy importantAmenities, ({location}) -> location.lat
        maxX = _.maxBy importantAmenities, ({location}) -> location.lon
        maxY = _.maxBy importantAmenities, ({location}) -> location.lat

        {
          x1: minX.location.lon
          y1: maxY.location.lat
          x2: maxX.location.lon
          y2: minY.location.lat
        }



module.exports = new CampgroundCtrl()
