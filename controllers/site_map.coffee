_ = require 'lodash'
Promise = require 'bluebird'
router = require 'exoid-router'

Campground = require '../models/campground'
Item = require '../models/item'
Product = require '../models/product'
Category = require '../models/category'
paths = require '../lang/en/paths_en.json'
config = require '../config'

getRoute = (key, replacements, {route} = {}) ->
  route ?= paths[key]
  unless route
    console.log 'missing route', key, replacements
  _.forEach replacements, (value, find) ->
    route = route.replace ":#{find}", value
  route

class SiteMapCtrl
  getAll: (req, res, next) =>
    Promise.all [
      @getCampgroundPages()

      @getGroupPages()

      @getItemPages()

      @getItemCategoryPages()

      @getProductPages()

      @getStaticPages()
    ]
    .then (routes) ->
      res.json _.flatten routes
    .catch next

  getItemPages: ->
    Item.getAll {limit: 9999}
    .then (items) ->
      _.map items, (item) ->
        getRoute 'item', {slug: item.slug}

  getItemCategoryPages: ->
    Category.getAll {limit: 9999}
    .then (categories) ->
      _.map categories, (category) ->
        getRoute 'itemsByCategory', {category: category.slug}

  getProductPages: ->
    Product.getAll {limit: 9999}
    .then (products) ->
      _.map products, (product) ->
        getRoute 'product', {slug: product.slug}

  getGroupPages: ->
    groupPaths = _.filter paths, (path) ->
      path.indexOf('/g/') isnt -1 and path.indexOf('/admin/') is -1 and
        (path.match(/:/g) or []).length is 1
    groups = ['freeroam']
    _.flatten _.map groups, (group) ->
      _.map groupPaths, (path) ->
        getRoute null, {groupId: group}, {route: path}

  getCampgroundPages: ->
    Campground.getAll {limit: 9999}
    .then (campgrounds) ->
      _.map campgrounds, (campground) ->
        getRoute 'campground', {slug: campground.slug}

  getStaticPages: ->
    staticPaths = _.filter paths, (path) ->
      path.indexOf(':') is -1 and path.indexOf('*') is -1



module.exports = new SiteMapCtrl()
