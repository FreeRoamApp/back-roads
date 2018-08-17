_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

# update the scores for posts up until they're 10 days old
SCORE_UPDATE_TIME_RANGE_S = 3600 * 24 * 10
ONE_HOUR_SECONDS = 3600
MAX_UNIQUE_ID_ATTEMPTS = 10

defaultThread = (thread) ->
  unless thread?
    return null

  thread.data?.lastUpdateTime = new Date()
  thread.data = JSON.stringify thread.data

  _.defaults thread, {
    uuid: cknex.getTimeUuid()
    userUuid: null
    category: 'general'
    data: {}
    timeBucket: 'MONTH-' + moment().format 'YYYY-MM'
  }

defaultThreadOutput = (thread) ->
  unless thread?.uuid
    return null

  thread.data = try
    JSON.parse thread.data
  catch error
    {}

  thread.userUuid = "#{thread.userUuid}"
  thread.time = thread.uuid.getDate()

  thread


tables = [
  {
    name: 'threads_counter_by_uuid'
    fields:
      uuid: 'timeuuid'
      upvotes: 'counter'
      downvotes: 'counter'
    primaryKey:
      partitionKey: ['uuid']
      clusteringColumns: null
  }
  {
    name: 'threads_recent'
    keyspace: 'free_roam'
    fields:
      partition: 'int' # always 1
      uuid: 'timeuuid'
      groupUuid: 'uuid'
      category: 'text'
    primaryKey:
      partitionKey: ['partition']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  {
    name: 'threads_by_groupUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      category: 'text'
      data: 'text'
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['groupUuid', 'timeBucket']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  {
    name: 'threads_by_groupUuid_and_category'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      category: 'text'
      data: 'text'
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['groupUuid', 'category', 'timeBucket']
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  {
    name: 'threads_by_userUuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      category: 'text'
      data: 'text' # title, body, type, attachmentIds/attachments?, lastUpdateTime
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['userUuid'] # may want to restructure with timeBucket
      clusteringColumns: ['uuid']
    withClusteringOrderBy: ['uuid', 'desc']
  }
  {
    name: 'threads_by_uuid'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      category: 'text'
      data: 'text' # title, body, type, attachmentIds/attachments?
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['uuid']
  }
  {
    name: 'threads_by_id'
    keyspace: 'free_roam'
    fields:
      uuid: 'timeuuid'
      id: 'text'
      groupUuid: 'uuid'
      userUuid: 'uuid'
      category: 'text'
      data: 'text' # title, body, type, attachmentIds/attachments?
      timeBucket: 'text'
    primaryKey:
      partitionKey: ['id']
  }
]

class ThreadModel
  SCYLLA_TABLES: tables

  getUniqueId: (baseId, suffix, attempts = 0) =>
    if suffix is 1
      suffix = parseInt(Math.random() * 10000) # random # between 0 and 9999

    id = if suffix \
         then "#{baseId}-#{suffix}"
         else baseId
    @getById baseId
    .then (existingThread) =>
      if attempts > MAX_UNIQUE_ID_ATTEMPTS
        return uuid.v4()
      if existingThread
        @getUniqueId baseId, (suffix or 0) + 1, attempts  + 1
      else
        baseId

  upsert: (thread) ->
    id = _.kebabCase(thread.data.title)
    thread = defaultThread thread

    (if thread.id
      Promise.resolve thread.id
    else
      @getUniqueId id)
    .then (id) ->
      thread.id = id

      Promise.all [
        cknex().insert {
          partition: 1
          uuid: thread.uuid
          groupUuid: thread.groupUuid
          category: thread.category
        }
        .into 'threads_recent'
        .usingTTL SCORE_UPDATE_TIME_RANGE_S
        .run()

        cknex().update 'threads_by_groupUuid'
        .set _.omit thread, ['groupUuid', 'timeBucket', 'uuid']
        .where 'groupUuid', '=', thread.groupUuid
        .andWhere 'timeBucket', '=', thread.timeBucket
        .andWhere 'uuid', '=', thread.uuid
        .run()

        cknex().update 'threads_by_groupUuid_and_category'
        .set _.omit thread, ['groupUuid', 'category', 'timeBucket', 'uuid']
        .where 'groupUuid', '=', thread.groupUuid
        .andWhere 'category', '=', thread.category
        .andWhere 'timeBucket', '=', thread.timeBucket
        .andWhere 'uuid', '=', thread.uuid
        .run()

        cknex().update 'threads_by_userUuid'
        .set _.omit thread, ['userUuid', 'uuid']
        .where 'userUuid', '=', thread.userUuid
        .andWhere 'uuid', '=', thread.uuid
        .run()

        cknex().update 'threads_by_uuid'
        .set _.omit thread, ['uuid']
        .where 'uuid', '=', thread.uuid
        .run()

        cknex().update 'threads_by_id'
        .set _.omit thread, ['id']
        .where 'id', '=', thread.id
        .run()
      ]
    .then ->
      defaultThreadOutput thread

  getByUuid: (uuid, {preferCache, omitCounter} = {}) =>
    get = =>
      Promise.all [
        cknex().select '*'
        .from 'threads_by_uuid'
        .where 'uuid', '=', uuid
        .run {isSingle: true}

        if omitCounter then Promise.resolve(null) else @getCounterByUuid uuid
      ]
      .then ([thread, threadCounter]) ->
        if omitCounter
          thread
        else
          threadCounter or= {upvotes: 0, downvotes: 0}
          _.defaults thread, threadCounter
      .then defaultThreadOutput

    if preferCache
      key = "#{CacheService.PREFIXES.THREAD_BY_UUID}:#{uuid}:#{Boolean omitCounter}"
      CacheService.preferCache key, get, {expireSeconds: ONE_HOUR_SECONDS}
    else
      get()

  getById: (id, {preferCache, omitCounter} = {}) =>
    get = =>
      cknex().select '*'
      .from 'threads_by_id'
      .where 'id', '=', id
      .run {isSingle: true}
      .then (thread) =>
        if omitCounter
          thread
        else if thread
          @getCounterByUuid thread.uuid
          .then (threadCounter) ->
            threadCounter or= {upvotes: 0, downvotes: 0}
            _.defaults thread, threadCounter
      .then defaultThreadOutput

    if preferCache
      key = "#{CacheService.PREFIXES.THREAD_BY_ID}:#{id}:#{Boolean omitCounter}"
      CacheService.preferCache key, get, {expireSeconds: ONE_HOUR_SECONDS}
    else
      get()

  getStale: ->
    CacheService.tempSetGetAll CacheService.KEYS.STALE_THREAD_IDS
    .map (value) ->
      arr = value.split '|'
      {groupUuid: arr[0], category: arr[1], uuid: arr[2]}

  setStaleByThread: ({groupUuid, category, uuid}) ->
    key = CacheService.KEYS.STALE_THREAD_IDS
    CacheService.tempSetAdd key, "#{groupUuid}|#{category}|#{uuid}"

  getAllNewish: (limit) ->
    q = cknex().select '*'
    .from 'threads_recent'
    .where 'partition', '=', 1

    if limit
      q.limit limit

    q.run()

  getCounterByUuid: (uuid) ->
    cknex().select '*'
    .from 'threads_counter_by_uuid'
    .where 'uuid', '=', uuid
    .run {isSingle: true}

  getAllPinnedThreadUuids: ->
    # TODO: this may get very large. when that happens, probably should
    # move to scylla with each key having a 1 month expiry. or figure out
    # a different solution for updatescores
    key = CacheService.STATIC_PREFIXES.PINNED_THREAD_IDS
    CacheService.setGetAll key

  setPinnedThreadUuid: (threadUuid) ->
    key = CacheService.STATIC_PREFIXES.PINNED_THREAD_IDS
    CacheService.setAdd key, threadUuid

  deletePinnedThreadUuid: (threadUuid) ->
    key = CacheService.STATIC_PREFIXES.PINNED_THREAD_IDS
    CacheService.setRemove key, threadUuid

  updateScores: (type, groupUuids) =>
    # FIXME: also need to factor in time when grabbing threads. Even without
    # an upvote, threads need to eventually be updated for time increasing.
    # maybe do it by addTime up until 3 days, and run not as freq?
    Promise.all [
      @getAllPinnedThreadUuids()

      (if type is 'time' then @getAllNewish() else @getStale())
      .map ({uuid, groupUuid, category}) =>
        @getCounterByUuid uuid
        .then (threadCount) ->
          threadCount or= {upvotes: 0, downvotes: 0}
          _.defaults {uuid, groupUuid, category}, threadCount
    ]
    .then ([pinnedThreadUuids, threadCounts]) =>
      Promise.map threadCounts, (thread) =>
        # https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
        # ^ simplification in comments

        unless thread.uuid
          return

        uuid = if typeof thread.uuid is 'string' \
                   then cknex.getTimeUuidFromString thread.uuid
                   else thread.uuid
        addTime = uuid.getDate()

        # people heavily downvote, so offset it a bit...
        thread.upvotes += 1 # for the initial user vote
        rawScore = Math.abs(thread.upvotes * 1.5 - thread.downvotes)
        order = Math.log10(Math.max(Math.abs(rawScore), 1))
        sign = if rawScore > 0 then 1 else if rawScore < 0 then -1 else 0
        postAgeHours = (Date.now() - addTime.getTime()) / (3600 * 1000)
        if "#{thread.uuid}" in pinnedThreadUuids
          postAgeHours = 1
          sign = 1
          order = Math.log10(Math.max(Math.abs(9999), 1))
        score = sign * order / Math.pow(2, postAgeHours / 12)#3.76)
        score = Math.round(score * 1000000)
        @setScoreByThread thread, score
      , {concurrency: 50}

  setScoreByThread: ({groupUuid, category, uuid}, score) ->
    groupAllPrefix = CacheService.STATIC_PREFIXES
                    .THREAD_GROUP_LEADERBOARD_ALL
    groupAllKey = "#{groupAllPrefix}:#{groupUuid}"
    CacheService.leaderboardUpdate groupAllKey, uuid, score

    groupCategoryPrefix = CacheService.STATIC_PREFIXES
                          .THREAD_GROUP_LEADERBOARD_BY_CATEGORY
    groupCategoryKey = "#{groupCategoryPrefix}:#{groupUuid}:#{category}"
    CacheService.leaderboardUpdate groupCategoryKey, uuid, score

  getAll: (options = {}) =>
    {category, groupUuid, sort, skip, maxUuid, limit} = options
    limit ?= 20
    skip ?= 0
    (if sort is 'new'
      @getAllTimeSorted {category, groupUuid, maxUuid, limit}
    else
      @getAllScoreSorted {category, groupUuid, skip, limit})
    .map (thread) =>
      unless thread
        return
      @getCounterByUuid thread.uuid
      .then (threadCounter) ->
        threadCounter or= {upvotes: 0, downvotes: 0}
        _.defaults thread, threadCounter
    .map defaultThreadOutput

  # need skip for redis-style (score), maxUuid for scylla-style (time)
  getAllScoreSorted: ({category, groupUuid, skip, limit} = {}) ->
    (if category
      prefix = CacheService.STATIC_PREFIXES.THREAD_GROUP_LEADERBOARD_BY_CATEGORY
      CacheService.leaderboardGet "#{prefix}:#{groupUuid}:#{category}", {
        skip, limit
      }
    else
      prefix = CacheService.STATIC_PREFIXES.THREAD_GROUP_LEADERBOARD_ALL
      CacheService.leaderboardGet "#{prefix}:#{groupUuid}", {skip, limit}
    )
    .then (results) ->
      Promise.map _.chunk(results, 2), ([threadUuid, score]) ->
        cknex().select '*'
        .from 'threads_by_uuid'
        .where 'uuid', '=', threadUuid
        .run {isSingle: true}
      .filter (thread) ->
        thread

  getAllTimeSorted: ({category, groupUuid, maxUuid, limit} = {}) ->
    get = (timeBucket) ->
      if category
        q = cknex().select '*'
        .from 'threads_by_groupUuid_and_category'
        .where 'groupUuid', '=', groupUuid
        .andWhere 'category', '=', category
        .andWhere 'timeBucket', '=', timeBucket
      else
        q = cknex().select '*'
        .from 'threads_by_groupUuid'
        .where 'groupUuid', '=', groupUuid
        .andWhere 'timeBucket', '=', timeBucket

      if maxUuid
        q = q.andWhere 'uuid', '<', maxUuid

      q.limit limit
      .run()

    maxTime = if maxUuid \
              then cknex.getTimeUuidFromString(maxUuid).getDate()
              else undefined

    get 'MONTH-' + moment(maxTime).format 'YYYY-MM'
    .then (results) ->
      if results.length < limit
        get 'MONTH-' + moment(maxTime).subtract(1, 'month').format 'YYYY-MM'
        .then (moreResults) ->
          if _.isEmpty moreResults
            results
          else
            results.concat moreResults
      else
        results

  incrementByUuid: (uuid, diff) =>
    @getByUuid uuid, {preferCache: true, omitCounter: true}
    .then @setStaleByThrea

    q = cknex().update 'threads_counter_by_uuid'
    _.forEach diff, (amount, key) ->
      q = q.increment key, amount
    q.where 'uuid', '=', uuid
    .run()

  deleteByThread: (thread) ->
    groupAllPrefix = CacheService.STATIC_PREFIXES
                    .THREAD_GROUP_LEADERBOARD_ALL
    groupAllKey = "#{groupAllPrefix}:#{thread.groupUuid}"

    groupCategoryPrefix = CacheService.STATIC_PREFIXES
                          .THREAD_GROUP_LEADERBOARD_BY_CATEGORY
    groupCategoryKey = "#{groupCategoryPrefix}:" +
                        "#{thread.groupUuid}:#{thread.category}"

    Promise.all [
      CacheService.leaderboardDelete groupAllKey, thread.uuid
      CacheService.leaderboardDelete groupCategoryKey, thread.uuid

      cknex().delete()
      .from 'threads_recent'
      .where 'partition', '=', 1
      .andWhere 'uuid', '=', thread.uuid
      .run()

      cknex().delete()
      .from 'threads_by_groupUuid'
      .where 'groupUuid', '=', thread.groupUuid
      .andWhere 'timeBucket', '=', thread.timeBucket
      .andWhere 'uuid', '=', thread.uuid
      .run()

      cknex().delete()
      .from 'threads_by_groupUuid_and_category'
      .where 'groupUuid', '=', thread.groupUuid
      .andWhere 'category', '=', thread.category
      .andWhere 'timeBucket', '=', thread.timeBucket
      .andWhere 'uuid', '=', thread.uuid
      .run()

      cknex().delete()
      .from 'threads_by_userUuid'
      .where 'userUuid', '=', thread.userUuid
      .andWhere 'uuid', '=', thread.uuid
      .run()

      cknex().delete()
      .from 'threads_by_uuid'
      .where 'uuid', '=', thread.uuid
      .run()

      cknex().delete()
      .from 'threads_by_id'
      .where 'id', '=', thread.id
      .run()

      cknex().delete()
      .from 'threads_counter_by_uuid'
      .where 'uuid', '=', thread.uuid
      .run()
    ]

  deleteByUuid: (id) =>
    @getByUuid id
    .then @deleteByThread

  getAllByUserUuid: (userUuid) ->
    cknex().select '*'
    .from 'threads_by_userUuid'
    .where 'userUuid', '=', userUuid
    .run()

  deleteAllByUserUuid: (userUuid) =>
    @getAllByUserUuid userUuid
    .map @deleteByThread

  hasPermissionByUuidAndUser: (uuid, user, {level} = {}) =>
    unless user
      return Promise.resolve false

    @getByUuid uuid, {preferCache: true, omitCounter: true}
    .then (thread) =>
      @hasPermission thread, user, {level}

  hasPermission: (thread, user, {level} = {}) ->
    unless thread and user
      return false

    return user?.username is 'austin' or thread.userUuid is user.uuid

  sanitize: _.curry (requesterId, thread) ->
    _.pick thread, [
      'uuid'
      'id'
      'category'
      'userUuid'
      'user'
      'data'
      'groupUuid'
      'comments'
      'commentCount'
      'myVote'
      'score'
      'upvotes'
      'downvotes'
      'time'
      'embedded'
    ]

module.exports = new ThreadModel()
