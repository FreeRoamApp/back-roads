Promise = require 'bluebird'
gm = require('gm').subClass({imageMagick: true})
request = require 'request-promise'
_ = require 'lodash'

AWSService = require './aws'
config = require '../config'

DEFAULT_IMAGE_QUALITY = 85
SMALL_VIDEO_PREVIEW_WIDTH = 360
SMALL_VIDEO_PREVIEW_HEIGHT = 202
LARGE_VIDEO_PREVIEW_WIDTH = 512
LARGE_VIDEO_PREVIEW_HEIGHT = 288

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

  # Note: images are never removed from s3
  uploadImage: ({key, stream, contentType}) ->
    contentType ?= 'image/jpg'

    bucket = new AWSService.S3()

    new Promise (resolve, reject) ->
      bucket.upload
        Key: key
        Bucket: config.AWS.CDN_BUCKET
        Body: stream
        ContentType: contentType
      .send (err) ->
        if err
          reject err
        else
          resolve key

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
