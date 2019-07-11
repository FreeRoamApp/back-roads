Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'
exec = require('child_process').exec
request = require 'request-promise'
Storage = require('@google-cloud/storage').Storage
fs = require 'fs'
MBTiles = require '@mapbox/mbtiles'

Mvum = require '../models/mvum'
Office = require '../models/office'
FeatureLookupService = require '../services/feature_lookup'
config = require '../config'

storage = new Storage {
  projectId: config.GOOGLE_PROJECT_ID
  credentials: config.GOOGLE_PRIVATE_KEY_JSON
}

class MvumCtrl
  getAll: ({}, {user}) ->
    Mvum.getAll()

  _uploadMbtiles: (mbtilesFileName, uploadFileName) ->
    new Promise (resolve, reject) ->
      readStream = fs.createReadStream mbtilesFileName
      file = storage.bucket('free-roam-tile-server').file uploadFileName
      readStream.pipe file.createWriteStream {
        # gzip: true
        metadata: {contentType: 'application/x-sqlite3'}
      }
      .on 'finish', ->
        resolve uploadFileName
      .on 'error', reject

  _getMbtilesInfo: (mbtilesFileName) ->
    new Promise (resolve, reject) ->
      new MBTiles "#{mbtilesFileName}?mode=ro", (err, mbtiles) ->
        if err
          reject err
        mbtiles.getInfo (err, info) ->
          FeatureLookupService.getOfficeSlugByLocation {
            lat: info.center[1]
            lon: info.center[0]
          }
          .then (slug) ->
            Office.getBySlug slug
            .then (office) ->
              resolve {
                regionSlug: office.regionSlug
                center: info.center
                bounds: info.bounds
              }


  _urlToMbtiles: (url, pdfFileName, mbtilesFileName) ->
    request url, {encoding: null}
    .then (buffer) =>
      console.log 'req done'
      new Promise (resolve, reject) ->
        fs.writeFile pdfFileName, buffer, (err) ->
          console.log 'wrote'
          if err
            reject err
          else
            exec "gdal_translate #{pdfFileName} #{mbtilesFileName} -of MBTILES && gdaladdo -r lanczos #{mbtilesFileName} 2 4 8 16", (error, stdout, stderr) ->
              if error or stderr
                reject error or stderr
              else
                resolve()

  _cleanup: (pdfFileName, mbtilesFileName) ->
    fs.unlink pdfFileName, -> null
    fs.unlink mbtilesFileName, -> null

  upsert: ({name, url}, {user}) =>
    console.log url

    # FIXME: throw err if url isn't usfs
    pdfFileName = "/tmp/mvum-#{Date.now()}.pdf"
    mbtilesFileName = "/tmp/mvum-#{Date.now()}.mbtiles"

    # TODO: might be better to move this to separate service so it doesn't hog memory / crash?
    @_urlToMbtiles url, pdfFileName, mbtilesFileName
    .then =>
      # mbtilesFileName = "/tmp/mvum-1562808170733.mbtiles"
      @_getMbtilesInfo mbtilesFileName
      .then ({regionSlug, center, bounds}) =>
        slug = Mvum.getSlugFromRegionSlugAndCenter regionSlug, center
        console.log {
          slug: slug
          name: name
          url: url
          regionSlug: regionSlug
          polygon:
            type: 'envelope'
            coordinates: [
              [bounds[0], bounds[1]] # top left?
              [bounds[2], bounds[3]] # bottom right?
            ]
        }
        Promise.all [
          @_uploadMbtiles mbtilesFileName, "mvums/#{slug}.mbtiles"

          Mvum.upsert {
            id: slug # for elasticsearch
            slug: slug
            name: name
            url: url
            regionSlug: regionSlug
            polygon:
              type: 'envelope'
              coordinates: [
                [bounds[0], bounds[1]] # top left?
                [bounds[2], bounds[3]] # bottom right?
              ]
          }
      ]
    .then =>
      @_cleanup pdfFileName, mbtilesFileName



module.exports = new MvumCtrl()
