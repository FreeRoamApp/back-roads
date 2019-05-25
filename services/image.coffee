Promise = require 'bluebird'
gm = require('gm').subClass({imageMagick: true})
request = require 'request-promise'
Storage = require('@google-cloud/storage').Storage
_ = require 'lodash'
generate = require 'node-chartist'
ctBarLabels = require 'chartist-bar-labels'

cknex = require '../services/cknex'
config = require '../config'
storage = new Storage {
  projectId: config.GOOGLE_PROJECT_ID
  credentials: config.GOOGLE_PRIVATE_KEY_JSON
}

DEFAULT_IMAGE_QUALITY = 85
SMALL_VIDEO_PREVIEW_WIDTH = 360
SMALL_VIDEO_PREVIEW_HEIGHT = 202
LARGE_VIDEO_PREVIEW_WIDTH = 512
LARGE_VIDEO_PREVIEW_HEIGHT = 288
TINY_IMAGE_SIZE = 144 # place tooltip
SMALL_IMAGE_SIZE = 256 # image thumbnails
LARGE_IMAGE_SIZE = 1024 # images

class ImageService
  DEFAULT_IMAGE_QUALITY: DEFAULT_IMAGE_QUALITY

  getSizeByBuffer: (buffer) ->
    new Promise (resolve, reject) ->
      gm(buffer)
      .size (err, size) ->
        if err
          reject err
        else
          resolve size

  toStream: ({buffer, path, width, height, quality, type, useMin}) ->
    quality ?= DEFAULT_IMAGE_QUALITY
    type ?= 'jpg'

    image = gm(buffer or path).autoOrient()

    if width or height
      mode = if width and height and not useMin then '^' else null
      image = image
        .resize width or height, height or width, mode

      if height
        image = image
        .gravity 'Center'
        .crop width, height, 0, 0

    if type is 'jpg'
      image = image
        .interlace 'Line' # progressive jpeg

    return image
      .quality quality
      .stream type

  # Note: images are never removed from gcloud
  uploadImage: ({key, stream, contentType}) ->
    contentType ?= 'image/jpg'

    new Promise (resolve, reject) ->
      file = storage.bucket('fdn.uno').file key
      stream.pipe file.createWriteStream {
        gzip: true
        metadata: {contentType}
      }
      .on 'finish', ->
        resolve key
      .on 'error', reject

  _getDimensions: ({size, max}) ->
    aspectRatio = size.width / size.height
    if (aspectRatio < 1 and aspectRatio < 10) or aspectRatio < 0.1
      width = Math.min(size.width, max)
      height = width / aspectRatio
    else
      height = Math.min(size.height, max)
      width = height * aspectRatio
    {width, height}

  uploadImageByUserIdAndFile: (userId, file, options = {}) =>
    {folder, tinySize, smallSize, largeSize, useMin} = options
    folder ?= 'misc'
    useMin ?= true
    id = cknex.getTimeUuid()

    @getSizeByBuffer file.buffer
    .then (size) =>
      key = "#{userId}_#{id}"
      keyPrefix = "#{folder}/#{key}"

      # 10 is to prevent super wide/tall images from being uploaded
      tinySize ?= @_getDimensions {size, max: TINY_IMAGE_SIZE}
      smallSize ?= @_getDimensions {size, max: SMALL_IMAGE_SIZE}
      largeSize ?= @_getDimensions {size, max: LARGE_IMAGE_SIZE}

      Promise.all [
        @uploadImage
          key: "images/#{keyPrefix}.tiny.jpg"
          stream: @toStream
            buffer: file.buffer
            width: tinySize.width
            height: tinySize.height
            useMin: useMin

        @uploadImage
          key: "images/#{keyPrefix}.small.jpg"
          stream: @toStream
            buffer: file.buffer
            width: smallSize.width
            height: smallSize.height
            useMin: useMin

        @uploadImage
          key: "images/#{keyPrefix}.large.jpg"
          stream: @toStream
            buffer: file.buffer
            width: largeSize.width
            height: largeSize.height
            useMin: useMin
      ]
      .then ->
        aspectRatio = Math.round(100 * largeSize.width / largeSize.height) / 100
        {aspectRatio, id, prefix: keyPrefix}

  uploadWeatherImageByPlace: (place, {type} = {}) ->
    type ?= 'campground'
    months = place?.weather?.months
    unless months
      throw new Error 'no weather found'

    lineOptions = {
      width: 400, height: 200
      fullWidth: true
      chartPadding:
        top: 12
        right: 30
        bottom: 0
        left: 4
      axisX:
        textAnchor: 'middle'
        showGrid: false
      axisY:
        labelInterpolationFnc: (text) ->
          text + '°F'
    }
    lineData = {
      labels: _.keys months
      series: [
        {
          className: 'tmin'
          data: _.map months, 'tmin'
        }
        {
          className: 'tmax'
          data: _.map months, 'tmax'
        }
      ]
    }

    precipData = _.map months, ({precip}) ->
      if precip < 0
        0
      else
        precip

    barOptions = (Chartist) ->
      {
        width: 434, height: 200
        fullWidth: true
        chartPadding:
          top: 12
          right: 0
          bottom: 0
          left: 40
        axisX:
          showGrid: false
          showLabel: false
        axisY:
          showGrid: false
          position: 'end'
          showLabel: false
          high: _.max(precipData) * 2
        plugins:
          [
            ctBarLabels({
              position: {
                y: (data) ->
                  return data.y2 - 4
              }
              labelInterpolationFnc: (text) ->
                return text  + '"'
            }, Chartist)
          ]

      }
    barData = {
      labels: _.keys months
      series: [
        {
          className: 'precip'
          data: precipData
        }
      ]
    }
    Promise.all [
      generate('bar', barOptions, barData)
      generate('line', lineOptions, lineData)
    ]
    .then ([barHtml, lineHtml]) ->
      barHtml = barHtml.replace '<div class="ct-chart"><svg xmlns:ct="http://gionkunz.github.com/chartist-js/ct" width="434" height="200" class="ct-chart-bar">', ''
      barHtml = barHtml.replace '</svg>', ''
      barHtml = barHtml.split('\n')[0]

      lineHtml = lineHtml.replace '<div class="ct-chart"><svg xmlns:ct="http://gionkunz.github.com/chartist-js/ct" width="400" height="200" class="ct-chart-line">', ''
      lineHtml = lineHtml.replace '</svg>', ''
      lineHtml = lineHtml.split('\n')[0]

      svg = """
    <?xml version="1.0"?>
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ct="http://gionkunz.github.com/chartist-js/ct" width="400" height="200" class="ct-chart-bar">
    <style>svg{font-family:verdana}.ct-label{fill:rgba(0,0,0,.4);color:rgba(0,0,0,.4);font-size:9px;line-height:1}.ct-bar,.ct-grid-background,.ct-line{fill:none}.ct-chart-bar .ct-label,.ct-chart-line .ct-label{display:block;display:-webkit-box;display:-moz-box;display:-ms-flexbox;display:-webkit-flex;display:flex}.ct-label.ct-vertical.ct-start{-webkit-box-align:flex-end;-webkit-align-items:flex-end;-ms-flex-align:flex-end;align-items:flex-end;-webkit-box-pack:flex-end;-webkit-justify-content:flex-end;-ms-flex-pack:flex-end;justify-content:flex-end;text-align:right;text-anchor:end}.ct-label.ct-vertical.ct-end{-webkit-box-align:flex-end;-webkit-align-items:flex-end;-ms-flex-align:flex-end;align-items:flex-end;-webkit-box-pack:flex-start;-webkit-justify-content:flex-start;-ms-flex-pack:flex-start;justify-content:flex-start;text-align:left;text-anchor:start}.ct-chart-bar .ct-label.ct-horizontal.ct-start{-webkit-box-align:flex-end;-webkit-align-items:flex-end;-ms-flex-align:flex-end;align-items:flex-end;-webkit-box-pack:center;-webkit-justify-content:center;-ms-flex-pack:center;justify-content:center;text-align:center;text-anchor:start}.ct-chart-bar .ct-label.ct-horizontal.ct-end{-webkit-box-align:flex-start;-webkit-align-items:flex-start;-ms-flex-align:flex-start;align-items:flex-start;-webkit-box-pack:center;-webkit-justify-content:center;-ms-flex-pack:center;justify-content:center;text-align:center;text-anchor:start;text-transform:uppercase;font-size:9px}.ct-chart-bar.ct-horizontal-bars .ct-label.ct-horizontal.ct-start{-webkit-box-align:flex-end;-webkit-align-items:flex-end;-ms-flex-align:flex-end;align-items:flex-end;-webkit-box-pack:flex-start;-webkit-justify-content:flex-start;-ms-flex-pack:flex-start;justify-content:flex-start;text-align:left;text-anchor:start}.ct-chart-bar.ct-horizontal-bars .ct-label.ct-horizontal.ct-end{-webkit-box-align:flex-start;-webkit-align-items:flex-start;-ms-flex-align:flex-start;align-items:flex-start;-webkit-box-pack:flex-start;-webkit-justify-content:flex-start;-ms-flex-pack:flex-start;justify-content:flex-start;text-align:left;text-anchor:start}.ct-chart-bar.ct-horizontal-bars .ct-label.ct-vertical.ct-start{-webkit-box-align:center;-webkit-align-items:center;-ms-flex-align:center;align-items:center;-webkit-box-pack:flex-end;-webkit-justify-content:flex-end;-ms-flex-pack:flex-end;justify-content:flex-end;text-align:right;text-anchor:end}.ct-chart-bar.ct-horizontal-bars .ct-label.ct-vertical.ct-end{-webkit-box-align:center;-webkit-align-items:center;-ms-flex-align:center;align-items:center;-webkit-box-pack:flex-start;-webkit-justify-content:flex-start;-ms-flex-pack:flex-start;justify-content:flex-start;text-align:left;text-anchor:end}.ct-grid{stroke:rgba(0,0,0,.2);stroke-width:1px;stroke-dasharray:2px;transform:scaleX(1.2) translateX(-10px);-webkit-transform:scaleX(1.2) translateX(-10px);}.ct-point{stroke-width:10px;stroke-linecap:round}.ct-line{stroke-width:4px}.ct-bar{stroke-width:20px}.ct-bar-label{font-size:9px;stroke:none}.tmin{stroke:#46b9d6;transform:translateX(10px);-webkit-transform:translateX(10px)}.tmax{stroke:#e98383;transform:translateX(10px);-webkit-transform:translateX(10px)}.precip{stroke:#2875d3}</style>
    #{barHtml}
    #{lineHtml}
    </svg>
    """
      contentType = 'image/svg+xml'

      new Promise (resolve, reject) ->
        key = "images/weather/#{type}_#{place.id}.svg"
        console.log key
        file = storage.bucket('fdn.uno').file key

        file.createWriteStream {
          gzip: true
          metadata: {contentType}
        }
        .on 'finish', ->
          resolve key
        .on 'error', (err) ->
          console.log 'err', err
          reject err
        .end(svg)

  getYoutubePreview: (keyPrefix, youtubeId) =>
    unless youtubeId
      return Promise.resolve null
    previewUrl = "https://img.youtube.com/vi/#{youtubeId}/maxresdefault.jpg"
    request previewUrl, {encoding: null}
    .catch (err) ->
      console.log 'preview fetch fail', previewUrl
      smallerPreviewUrl = "https://img.youtube.com/vi/#{youtubeId}/0.jpg"
      request smallerPreviewUrl, {encoding: null}
    .then (buffer) =>
      @getSizeByBuffer (buffer)
      .then (size) =>
        Promise.all [
          @uploadImage
            key: "#{keyPrefix}.small.png"
            stream: @toStream
              buffer: buffer
              width: SMALL_VIDEO_PREVIEW_WIDTH
              height: SMALL_VIDEO_PREVIEW_HEIGHT

          @uploadImage
            key: "#{keyPrefix}.large.png"
            stream: @toStream
              buffer: buffer
              width: LARGE_VIDEO_PREVIEW_WIDTH
              height: LARGE_VIDEO_PREVIEW_HEIGHT
        ]
      .then (imageKeys) ->
        _.map imageKeys, (imageKey) ->
          "https://#{config.CDN_HOST}/#{imageKey}"
      .then ([smallUrl, largeUrl]) ->
        {
          originalUrl: largeUrl
          versions: [
            {
              width: SMALL_VIDEO_PREVIEW_WIDTH
              height: SMALL_VIDEO_PREVIEW_HEIGHT
              url: smallUrl
            }
            {
              width: LARGE_VIDEO_PREVIEW_WIDTH
              height: LARGE_VIDEO_PREVIEW_HEIGHT
              url: largeUrl
            }
          ]
        }
    .catch ->
      console.log 'failed to upload'
      null

module.exports = new ImageService()
