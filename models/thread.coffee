_ = require 'lodash'
uuid = require 'node-uuid'
Promise = require 'bluebird'
moment = require 'moment'

Base = require './base'
cknex = require '../services/cknex'
CacheService = require '../services/cache'
config = require '../config'

# update the scores for posts up until they're 10 days old
SCORE_UPDATE_TIME_RANGE_S = 3600 * 24 * 10
ONE_HOUR_SECONDS = 3600
MAX_UNIQUE_ID_ATTEMPTS = 10

scyllaFields =
  id: 'timeuuid'
  slug: 'text'
  groupId: 'uuid'
  userId: 'uuid'
  category: {type: 'text', defaultFn: -> 'general'}
  title: 'text'
  body: 'text'
  attachments: 'json'
  lastUpdateTime: {type: 'timestamp', defaultFn: -> new Date()}
  isPinned: 'boolean'
  timeBucket: {type: 'text', defaultFn: -> 'MONTH-' + moment().format 'YYYY-MM'}

class ThreadModel extends Base
  getScyllaTables: ->
    [
      {
        name: 'threads_by_groupId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['groupId', 'timeBucket']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'threads_by_groupId_and_category'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['groupId', 'category', 'timeBucket']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'threads_by_userId'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['userId'] # may want to restructure with timeBucket
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
      {
        name: 'threads_by_id'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['id']
      }
      {
        name: 'threads_by_slug'
        keyspace: 'free_roam'
        fields: scyllaFields
        primaryKey:
          partitionKey: ['slug']
      }
      {
        name: 'threads_counter_by_id'
        ignoreUpsert: true
        fields:
          id: 'timeuuid'
          upvotes: 'counter'
          downvotes: 'counter'
        primaryKey:
          partitionKey: ['id']
          clusteringColumns: null
      }
      {
        name: 'threads_counter_by_userId'
        ignoreUpsert: true
        fields:
          id: 'timeuuid'
          userId: 'uuid'
          upvotes: 'counter'
          downvotes: 'counter'
        primaryKey:
          partitionKey: ['userId']
          clusteringColumns: ['id']
      }
      {
        name: 'threads_recent'
        keyspace: 'free_roam'
        ignoreUpsert: true
        fields:
          partition: 'int' # always 1
          id: 'timeuuid'
          groupId: 'uuid'
          category: 'text'
        primaryKey:
          partitionKey: ['partition']
          clusteringColumns: ['id']
        withClusteringOrderBy: ['id', 'desc']
      }
    ]

  getUniqueSlug: (baseSlug, suffix, attempts = 0) =>
    if suffix is 1
      suffix = parseInt(Math.random() * 10000) # random # between 0 and 9999

    slug = if suffix \
         then "#{baseSlug}-#{suffix}"
         else baseSlug
    @getBySlug slug, {preferCache: true}
    .then (existingThread) =>
      if attempts > MAX_UNIQUE_ID_ATTEMPTS
        return "#{baseSlug}-#{Date.now()}"
      if existingThread
        @getUniqueSlug baseSlug, (suffix or 0) + 1, attempts  + 1
      else
        slug

  upsert: (thread) =>
    slug = _.kebabCase(thread.title)
    (if thread.slug
      Promise.resolve thread.slug
    else
      @getUniqueSlug slug)
    .then (slug) =>
      thread = _.defaults thread, {
        id: cknex.getTimeUuid()
        userId: null
        category: 'general'
        slug: slug
      }

      cknex().insert {
        partition: 1
        id: thread.id
        groupId: thread.groupId
        category: thread.category
      }
      .into 'threads_recent'
      .usingTTL SCORE_UPDATE_TIME_RANGE_S
      .run()
      .then =>
        super thread

  getById: (id, {preferCache, omitCounter} = {}) =>
    get = =>
      Promise.all [
        cknex().select '*'
        .from 'threads_by_id'
        .where 'id', '=', id
        .run {isSingle: true}

        if omitCounter then Promise.resolve(null) else @getCounterById id
      ]
      .then ([thread, threadCounter]) ->
        if omitCounter
          thread
        else
          threadCounter or= {upvotes: 0, downvotes: 0}
          _.defaults thread, threadCounter
      .then @defaultOutput

    if preferCache
      key = "#{CacheService.PREFIXES.THREAD_BY_ID}:#{id}:#{Boolean omitCounter}"
      CacheService.preferCache key, get, {
        expireSeconds: ONE_HOUR_SECONDS
        category: CacheService.PREFIXES.THREAD_BY_ID_CATEGORY + ':' + id
      }
    else
      get()

  getBySlug: (slug, {preferCache, omitCounter} = {}) =>
    get = =>
      cknex().select '*'
      .from 'threads_by_slug'
      .where 'slug', '=', slug
      .run {isSingle: true}
      .then (thread) =>
        if omitCounter
          thread
        else if thread
          @getCounterById thread.id
          .then (threadCounter) ->
            threadCounter or= {upvotes: 0, downvotes: 0}
            _.defaults thread, threadCounter
      .then @defaultOutput

    if preferCache
      key = "#{CacheService.PREFIXES.THREAD_BY_SLUG}:#{slug}:#{Boolean omitCounter}"
      CacheService.preferCache key, get, {
        expireSeconds: ONE_HOUR_SECONDS
        category: CacheService.PREFIXES.THREAD_BY_SLUG_CATEGORY + ':' + slug
      }
    else
      get()

  getStale: ->
    CacheService.tempSetGetAll CacheService.KEYS.STALE_THREAD_IDS
    .map (value) ->
      arr = value.split '|'
      {groupId: arr[0], category: arr[1], id: arr[2]}

  setStaleByThread: ({groupId, category, id}) ->
    key = CacheService.KEYS.STALE_THREAD_IDS
    CacheService.tempSetAdd key, "#{groupId}|#{category}|#{id}"

  getAllNewish: (limit) ->
    q = cknex().select '*'
    .from 'threads_recent'
    .where 'partition', '=', 1

    if limit
      q.limit limit

    q.run()

  getCounterById: (id) ->
    cknex().select '*'
    .from 'threads_counter_by_id'
    .where 'id', '=', id
    .run {isSingle: true}

  getAllPinnedThreadIds: ->
    # TODO: this may get very large. when that happens, probably should
    # move to scylla with each key having a 1 month expiry. or figure out
    # a different solution for updatescores
    key = CacheService.STATIC_PREFIXES.PINNED_THREAD_IDS
    CacheService.setGetAll key

  setPinnedThreadId: (threadId) ->
    key = CacheService.STATIC_PREFIXES.PINNED_THREAD_IDS
    CacheService.setAdd key, threadId

  deletePinnedThreadId: (threadId) ->
    key = CacheService.STATIC_PREFIXES.PINNED_THREAD_IDS
    CacheService.setRemove key, threadId

  updateScores: (type, groupIds) =>
    # FIXME: also need to factor in time when grabbing threads. Even without
    # an upvote, threads need to eventually be updated for time increasing.
    # maybe do it by addTime up until 3 days, and run not as freq?
    Promise.all [
      @getAllPinnedThreadIds()

      (if type is 'time' then @getAllNewish() else @getStale())
      .map ({id, groupId, category}) =>
        @getCounterById id
        .then (threadCount) ->
          threadCount or= {upvotes: 0, downvotes: 0}
          _.defaults {id, groupId, category}, threadCount
    ]
    .then ([pinnedThreadIds, threadCounts]) =>
      Promise.map threadCounts, (thread) =>
        # https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
        # ^ simplification in comments

        unless thread.id
          return

        id = if typeof thread.id is 'string' \
                   then cknex.getTimeUuidFromString thread.id
                   else thread.id
        addTime = id.getDate()

        # people heavily downvote, so offset it a bit...
        thread.upvotes += 1 # for the initial user vote
        rawScore = Math.abs(thread.upvotes * 1.5 - thread.downvotes)
        order = Math.log10(Math.max(Math.abs(rawScore), 1))
        sign = if rawScore > 0 then 1 else if rawScore < 0 then -1 else 0
        postAgeHours = (Date.now() - addTime.getTime()) / (3600 * 1000)
        if "#{thread.id}" in pinnedThreadIds
          postAgeHours = 1
          sign = 1
          order = Math.log10(Math.max(Math.abs(9999), 1))
        score = sign * order / Math.pow(2, postAgeHours / 12)#3.76)
        score = Math.round(score * 1000000)
        @setScoreByThread thread, score
      , {concurrency: 50}

  setScoreByThread: ({groupId, category, id}, score) ->
    groupAllPrefix = CacheService.STATIC_PREFIXES
                    .THREAD_KARMA_LEADERBOARD_ALL
    groupAllKey = "#{groupAllPrefix}:#{groupId}"
    CacheService.leaderboardUpdate groupAllKey, id, score

    groupCategoryPrefix = CacheService.STATIC_PREFIXES
                          .THREAD_KARMA_LEADERBOARD_BY_CATEGORY
    groupCategoryKey = "#{groupCategoryPrefix}:#{groupId}:#{category}"
    CacheService.leaderboardUpdate groupCategoryKey, id, score

  getAll: (options = {}) =>
    {category, groupId, sort, skip, maxId, limit} = options
    limit ?= 20
    skip ?= 0
    (if sort is 'new'
      @getAllTimeSorted {category, groupId, maxId, limit}
    else
      @getAllScoreSorted {category, groupId, skip, limit})
    .map (thread) =>
      unless thread
        return
      @getCounterById thread.id
      .then (threadCounter) ->
        threadCounter or= {upvotes: 0, downvotes: 0}
        _.defaults thread, threadCounter
    .map @defaultOutput

  # need skip for redis-style (score), maxId for scylla-style (time)
  getAllScoreSorted: ({category, groupId, skip, limit} = {}) ->
    (if category
      prefix = CacheService.STATIC_PREFIXES.THREAD_KARMA_LEADERBOARD_BY_CATEGORY
      CacheService.leaderboardGet "#{prefix}:#{groupId}:#{category}", {
        skip, limit
      }
    else
      prefix = CacheService.STATIC_PREFIXES.THREAD_KARMA_LEADERBOARD_ALL
      CacheService.leaderboardGet "#{prefix}:#{groupId}", {skip, limit}
    )
    .then (results) ->
      Promise.map _.chunk(results, 2), ([threadId, score]) ->
        cknex().select '*'
        .from 'threads_by_id'
        .where 'id', '=', threadId
        .run {isSingle: true}
      .filter (thread) ->
        thread

  getAllTimeSorted: ({category, groupId, maxId, limit} = {}) ->
    get = (timeBucket) ->
      if category
        q = cknex().select '*'
        .from 'threads_by_groupId_and_category'
        .where 'groupId', '=', groupId
        .andWhere 'category', '=', category
        .andWhere 'timeBucket', '=', timeBucket
      else
        q = cknex().select '*'
        .from 'threads_by_groupId'
        .where 'groupId', '=', groupId
        .andWhere 'timeBucket', '=', timeBucket

      if maxId
        q = q.andWhere 'id', '<', maxId

      q.limit limit
      .run()

    maxTime = if maxId \
              then cknex.getTimeUuidFromString(maxId).getDate()
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

  voteByParent: (parent, diff, userId) =>
    @getById parent.id, {preferCache: true, omitCounter: true}
    .then @setStaleByThread

    qByUserId = cknex().update 'threads_counter_by_userId'
    _.forEach values, (value, key) ->
      qByUserId = qByUserId.increment key, value
    qByUserId = qByUserId.where 'userId', '=', userId
    .andWhere 'id', '=', parent.id
    .run()

    qByTopId = cknex().update 'threads_counter_by_id'
    _.forEach values, (value, key) ->
      qByTopId = qByTopId.increment key, value
    qByTopId = qByTopId.where 'id', '=', parent.id
    .andWhere 'id', '=', parent.id
    .run()

    Promise.all [
      qByUserId
      qByTopId
    ]

  # TODO: super() (deleteByRow)
  deleteByThread: (thread) ->
    groupAllPrefix = CacheService.STATIC_PREFIXES
                    .THREAD_KARMA_LEADERBOARD_ALL
    groupAllKey = "#{groupAllPrefix}:#{thread.groupId}"

    groupCategoryPrefix = CacheService.STATIC_PREFIXES
                          .THREAD_KARMA_LEADERBOARD_BY_CATEGORY
    groupCategoryKey = "#{groupCategoryPrefix}:" +
                        "#{thread.groupId}:#{thread.category}"

    Promise.all [
      CacheService.leaderboardDelete groupAllKey, thread.id
      CacheService.leaderboardDelete groupCategoryKey, thread.id

      cknex().delete()
      .from 'threads_recent'
      .where 'partition', '=', 1
      .andWhere 'id', '=', thread.id
      .run()

      cknex().delete()
      .from 'threads_by_groupId'
      .where 'groupId', '=', thread.groupId
      .andWhere 'timeBucket', '=', thread.timeBucket
      .andWhere 'id', '=', thread.id
      .run()

      cknex().delete()
      .from 'threads_by_groupId_and_category'
      .where 'groupId', '=', thread.groupId
      .andWhere 'category', '=', thread.category
      .andWhere 'timeBucket', '=', thread.timeBucket
      .andWhere 'id', '=', thread.id
      .run()

      cknex().delete()
      .from 'threads_by_userId'
      .where 'userId', '=', thread.userId
      .andWhere 'id', '=', thread.id
      .run()

      cknex().delete()
      .from 'threads_by_id'
      .where 'id', '=', thread.id
      .run()

      cknex().delete()
      .from 'threads_by_slug'
      .where 'slug', '=', thread.slug
      .run()

      cknex().delete()
      .from 'threads_counter_by_id'
      .where 'id', '=', thread.id
      .run()
    ]

  deleteById: (id) =>
    @getById id
    .then @deleteByThread

  getAllByUserId: (userId) ->
    cknex().select '*'
    .from 'threads_by_userId'
    .where 'userId', '=', userId
    .run()

  deleteAllByUserId: (userId) =>
    @getAllByUserId userId
    .map @deleteByThread

  hasPermissionByIdAndUser: (id, user, {level} = {}) =>
    unless user
      return Promise.resolve false

    @getById id, {preferCache: true, omitCounter: true}
    .then (thread) =>
      @hasPermission thread, user, {level}

  hasPermission: (thread, user, {level} = {}) ->
    unless thread and user
      return false

    return user?.username is 'austin' or thread.userId is user.id

  sanitize: _.curry (requesterId, thread) ->
    _.pick thread, [
      'id'
      'slug'
      'category'
      'userId'
      'user'
      'title'
      'body'
      'attachments'
      'groupId'
      'comments'
      'commentCount'
      'lastUpdateTime'
      'myVote'
      'score'
      'upvotes'
      'downvotes'
      'time'
      'embedded'
    ]

module.exports = new ThreadModel()
