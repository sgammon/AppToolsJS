class SimpleKeyEncoder extends KeyEncoder

    constructor: () ->

        ## Key Operations
        @build_key = () =>
        @encode_key = () =>

        ## Cluster Operations
        @build_cluster = () =>
        @encode_cluster = () =>

_simple_key_encoder = new SimpleKeyEncoder()


### === DOM Storage Engines === ###

## LocalStorage
class LocalStorageEngine extends StorageAdapter

    # Internal state
    @_state =

        # Runtime data
        runtime:

            # Key counts
            count:
                total_keys: 0
                by_kind: []


    constructor: (@name) ->

        # Async Methods
        @get_async = (key, callback) =>

            return callback.call(object = @get(key))

        @put_async = (key, value, callback) =>

            @put(key, value)
            return callback.call(value)

        @delete_async = (key, callback) =>

            @delete(key)
            return callback.call(@)

        @clear_async = (callback) =>

            @clear()
            return callback.call(@)

        # Non-Async Methods
        @get = (key) =>

            return localStorage.getItem(key)

        @put = (key, value) =>

            @_state.runtime.count.total_keys++ if not @get(key)?
            return localStorage.setItem(key, value)

        @delete = (key) =>

            @_state.runtime.count.total_keys--
            return localStorage.removeItem(key)

        @clear = () =>

            @_state.runtime.count.total_keys = 0
            return localStorage.clear()

        return

## SessionStorage
class SessionStorageEngine extends StorageAdapter

    # Internal state
    @_state =

        # Runtime data
        runtime:

            # Key counts
            count:
                total_keys: 0
                by_kind: []

    constructor: (@name) ->

        # Async Methods
        @get_async = (key, callback) =>

            return callback.call(object = @get(key))

        @put_async = (key, value, callback) =>

            @put(key, value)
            return callback.call(value)

        @delete_async = (key, callback) =>

            @delete(key)
            return callback.call(@)

        @clear_async = (callback) =>

            @clear()
            return callback.call(@)

        # Non-Async Methods
        @get = (key) =>

            return sessionStorage.getItem(key)

        @put = (key, value) =>

            @_state.runtime.count.total_keys++ if not @get(key)?
            return sessionStorage.setItem(key, value)

        @delete = (key) =>

            @_state.runtime.count.total_keys--
            return sessionStorage.removeItem(key)

        @clear = () =>

            @_state.runtime.count.total_keys = 0
            return sessionStorage.clear()

        return


### === DOM Storage Drivers === ###

## LocalStorage
class LocalStorageDriver extends StorageDriver

    # Internal state
    @_state =

    constructor: () ->

        # Check compatibility
        @compatible = () =>
            return !!window.localStorage

        # Construct a new backend
        @construct = (name='appstorage') =>

            return if @compatible() then new_engine = new LocalStorageEngine(name) else false

        return


## SessionStorage
class SessionStorageDriver extends StorageDriver

    # Internal state
    @_state =

    constructor: () ->

        # Check compatibility
        @compatible = () =>
            return !!window.sessionStorage

        # Construct a new backend
        @construct = (name='appstorage') =>

            return if @compatible() then new_engine = new SessionStorageEngine(name) else false

        return


@__apptools_preinit.detected_storage_engines.push {name: "LocalStorage", adapter: LocalStorageEngine, driver: LocalStorageDriver, key_encoder: _simple_key_encoder}
@__apptools_preinit.detected_storage_engines.push {name: "SessionStorage", adapter: SessionStorageEngine, driver: SessionStorageDriver, key_encoder: _simple_key_encoder}
