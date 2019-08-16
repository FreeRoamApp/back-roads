Promise = require 'bluebird'
gm = require('gm').subClass({imageMagick: true})
request = require 'request-promise'
Storage = require('@google-cloud/storage').Storage
_ = require 'lodash'

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
      # https://stackoverflow.com/a/45804023
      gm(buffer).autoOrient().toBuffer (err, buffer) ->
        gm(buffer).size (err, size) ->
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
      console.log 'size', size
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
