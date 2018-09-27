Promise = require 'bluebird'
gm = require('gm').subClass({imageMagick: true})
request = require 'request-promise'
Storage = require('@google-cloud/storage').Storage
_ = require 'lodash'
uuid = require 'node-uuid'

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
SMALL_IMAGE_SIZE = 200

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

    image = gm(buffer or path)

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
      .quality DEFAULT_IMAGE_QUALITY
      .stream type

  # Note: images are never removed from gcloud
  uploadImage: ({key, stream, contentType}) ->
    contentType ?= 'image/jpg'

    new Promise (resolve, reject) ->
      file = storage.bucket('fdn.uno').file key
      stream.pipe file.createWriteStream {
        gzip: true
        metaData: {contentType}
      }
      .on 'finish', ->
        resolve key
      .on 'error', reject

  uploadImageByUserIdAndFile: (userId, file, {folder} = {}) =>
    folder ?= 'misc'
    @getSizeByBuffer file.buffer
    .then (size) =>
      key = "#{userId}_#{uuid.v4()}"
      keyPrefix = "images/#{folder}/#{key}"

      aspectRatio = size.width / size.height
      # 10 is to prevent super wide/tall images from being uploaded
      if (aspectRatio < 1 and aspectRatio < 10) or aspectRatio < 0.1
        smallWidth = SMALL_IMAGE_SIZE
        smallHeight = smallWidth / aspectRatio
      else
        smallHeight = SMALL_IMAGE_SIZE
        smallWidth = smallHeight * aspectRatio

      Promise.all [
        @uploadImage
          key: "#{keyPrefix}.small.jpg"
          stream: @toStream
            buffer: file.buffer
            width: Math.min size.width, smallWidth
            height: Math.min size.height, smallHeight
            useMin: true

        @uploadImage
          key: "#{keyPrefix}.large.jpg"
          stream: @toStream
            buffer: file.buffer
            width: Math.min size.width, smallWidth * 5
            height: Math.min size.height, smallHeight * 5
            useMin: true
      ]
      .then (imageKeys) ->
        _.map imageKeys, (imageKey) ->
          "https://#{config.CDN_HOST}/#{imageKey}"
      .then ([smallUrl, largeUrl]) ->
        {
          aspectRatio, smallUrl, largeUrl, key
          width: size.width, height: size.height
        }

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
