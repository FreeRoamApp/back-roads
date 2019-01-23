_ = require 'lodash'
config = require '../config'

# overlaps with language model in fr
class Language
  constructor: ->
    files = {
      strings: null
      backend: null
      pushNotifications: null
    }

    @files = _.mapValues files, (val, file) ->
      file = _.snakeCase file
      _.reduce config.LANGUAGES, (obj, lang) ->
        obj[lang] = try require "../lang/#{lang}/#{file}_#{lang}.json" \
                    catch e then null
        obj
      , {}

  get: (strKey, {replacements, file, language} = {}) =>
    file ?= 'backend'
    language ?= 'en'
    baseResponse = @files[file][language]?[strKey] or
                    @files[file]['en']?[strKey] or ''

    unless baseResponse
      console.log 'missing', file, strKey

    if typeof baseResponse is 'object'
      # some languages (czech) have many plural forms
      pluralityCount = replacements[baseResponse.pluralityCheck]
      baseResponse = baseResponse.plurality[pluralityCount] or
                      baseResponse.plurality.other or ''

    _.reduce replacements, (str, replace, key) ->
      find = ///{#{key}}///g
      str.replace find, replace
    , baseResponse


module.exports = new Language()
