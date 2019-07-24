Promise = require 'bluebird'
_ = require 'lodash'
router = require 'exoid-router'
exec = require('child_process').exec
request = require 'request-promise'
Storage = require('@google-cloud/storage').Storage
fs = require 'fs'
MBTiles = require '@mapbox/mbtiles'

LocalMap = require '../models/local_map'
Office = require '../models/office'
FeatureLookupService = require '../services/feature_lookup'
config = require '../config'

storage = new Storage {
  projectId: config.GOOGLE_PROJECT_ID
  credentials: config.GOOGLE_PRIVATE_KEY_JSON
}

# missing georeferenced:
###
- Bighorn
- Mt. Baker
- Olympic
- George Washington and Jefferson
- Ashley
- Uinta-Wasatch-Cache
- Bitterroot
- Modoc

- Flathead: Swan Lake
- Helena-Lewis and Clark: Divide-Clancy-Unionville
- Helena-Lewis and Clark: Big Belt Mountains
- Helena-Lewis and Clark: Little Belt Mountains
- Helena-Lewis and Clark: Highwood Mountains
- Helena-Lewis and Clark: Big and Little Snowy Mountains
- Helena-Lewis and Clark: Lewis and Clark Interpretive Center
- Lolo: Missoula Ranger District  - Lolo Creek to Missoula West
- Lolo: Ninemile Ranger District South
- Lolo: Superior Ranger District
- Six Rivers: Orleans (south)
- Six Rivers: Orleans (north)
- Los Padres: Balling ohv
- Sequoia: Western Divide
- Sequoia: Hume Lake
- Lake Taoe Basin: North
- Lake Tahoe Basin: South
- Angeles: West
- Angeles: East
###


class LocalMapCtrl
  getAllByRegionSlug: ({regionSlug, location}, {user}) ->
    console.log 'get', regionSlug
    # TODO: get by location as well, and highlight that one
    LocalMap.getAllByRegionSlug regionSlug

  _uploadMbtiles: (mbtilesFileName, uploadFileName) ->
    new Promise (resolve, reject) ->
      readStream = fs.createReadStream mbtilesFileName
      file = storage.bucket('free-roam-tile-server').file uploadFileName
      readStream.pipe file.createWriteStream {
        metadata: {contentType: 'application/x-sqlite3'}
      }
      .on 'finish', ->
        resolve uploadFileName
      .on 'error', reject

  _uploadPdf: (pdfFileName, uploadFileName) ->
    new Promise (resolve, reject) ->
      readStream = fs.createReadStream pdfFileName
      file = storage.bucket('fdn.uno').file uploadFileName
      readStream.pipe file.createWriteStream {
        metadata: {contentType: 'application/pdf'}
      }
      .on 'finish', ->
        resolve uploadFileName
      .on 'error', reject

  _getMbtilesInfo: (mbtilesFileName, regionSlug) ->
    new Promise (resolve, reject) ->
      new MBTiles "#{mbtilesFileName}?mode=ro", (err, mbtiles) ->
        if err
          console.log 'tiles info err', err
          reject err
        mbtiles.getInfo (err, info) ->
          unless info.center?[1]
            reject {
              status: 400
              info:
                message: "This isn't a valid georeferenced PDF, we can't accept this at this time - post the URL in chat and we'll try to find one"
                field: 'url'
            }
          resolve {
            center: info.center
            bounds: info.bounds
          }


  _urlToPdfBuffer: (url) =>
    request url, {encoding: null}
    .catch ->
      throw {
        status: 400
        info:
          message: "Error fetching PDF"
          field: 'url'
      }

  _pdfToMbtiles: (buffer, pdfFileName, mbtilesFileName) ->
    new Promise (resolve, reject) ->
      fs.writeFile pdfFileName, buffer, (err) ->
        console.log 'wrote', err
        if err
          reject {
            status: 400
            info:
              message: "Error saving PDF"
              field: 'url'
          }
        else
          exec "gdal_translate #{pdfFileName} -co TILE_FORMAT=png8 -co BLOCKSIZE=512 #{mbtilesFileName} -of MBTILES && gdaladdo -r lanczos #{mbtilesFileName} 2 4 8 16 32 64", (error, stdout, stderr) ->
            if error or stderr
              console.log error or stderr
              reject {
                status: 400
                info:
                  message: "This doesn't appear to be a valid georeferenced PDF, we can't accept this at this time - post the URL in chat and we'll try to find one"
                  field: 'url'
              }
            else
              resolve()

  _cleanup: (pdfFileName, mbtilesFileName) ->
    fs.unlink pdfFileName, -> null
    fs.unlink mbtilesFileName, -> null

  deleteByRow: ({row}, {user}) ->
    if user?.username in ['austin', 'big_boxtruck']
      LocalMap.deleteByRow row


  upsert: ({name, type, url, regionSlug}, {user}) =>
    console.log url
    unless name
      router.throw {
        status: 400
        info:
          message: "Must enter a name"
          field: 'name'
      }

    # FIXME: throw err if url isn't usfs
    pdfFileName = "/tmp/localmap-#{Date.now()}.pdf"
    mbtilesFileName = "/tmp/localmap-#{Date.now()}.mbtiles"

    # TODO: might be better to move this to separate service so it doesn't hog memory / crash?
    @_urlToPdfBuffer url
    .catch (err) ->
      router.throw err
    .then (buffer) =>
      @_pdfToMbtiles buffer, pdfFileName, mbtilesFileName
      .then =>
        # mbtilesFileName = "/tmp/localmap-1562808170733.mbtiles"
        console.log 'get tiles info'
        @_getMbtilesInfo mbtilesFileName
        .catch (err) ->
          console.log err
          router.throw err
        .then ({center, bounds}) =>
          console.log 'got', center, bounds
          (if regionSlug
            Promise.resolve regionSlug
          else
            FeatureLookupService.getOfficeSlugByLocation {
              lat: center[1]
              lon: center[0]
            }
            .then (officeSlug) ->
              unless officeSlug
                return
              Office.getBySlug officeSlug
              .then (office) ->
                unless office?.regionSlug
                  throwLocationError
                office.regionSlug
          ).then (regionSlug) =>
            unless regionSlug
              router.throw {
                status: 400
                info:
                  message: "Couldn't automatically determine the national forest, you'll have to select it manually"
                  requestRegion: true
                  field: 'url'
              }
            slug = LocalMap.getSlugFromRegionSlugAndCenter regionSlug, center
            console.log "#{config.CDN_HOST}/local_maps/#{slug}.pdf"
            Promise.all [
              @_uploadMbtiles mbtilesFileName, "local_maps/#{slug}.mbtiles"

              @_uploadPdf pdfFileName, "local_maps/#{slug}.pdf"

              LocalMap.upsert {
                id: slug # for elasticsearch
                slug: slug
                name: name
                type: type
                url: url
                downloadUrl: "https://#{config.CDN_HOST}/local_maps/#{slug}.pdf"
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



module.exports = new LocalMapCtrl()
