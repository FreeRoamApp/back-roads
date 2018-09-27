_ = require 'lodash'
Promise = require 'bluebird'

Base = require './base'
cknex = require '../services/cknex'

module.exports = class AttachmentBase extends Base
  getAllByParentId: (parentId) =>
    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .where 'parentId', '=', parentId
    .run()
    .map @defaultOutput

  getAll: ({limit} = {}) =>
    limit ?= 30

    cknex().select '*'
    .from @SCYLLA_TABLES[0].name
    .limit limit
    .run()
    .map @defaultOutput
