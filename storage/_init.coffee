# Storage API
class CoreStorageAPI extends CoreAPI

    @mount = 'storage'
    @events = [
                # Storage events
                'STORAGE_INIT',
                'ENGINE_LOADED',
                'STORAGE_READY',
                'STORAGE_ERROR',
                'STORAGE_ACTIVITY',
                'STORAGE_READ',
                'STORAGE_WRITE',
                'STORAGE_DELETE'


                # Collection events
                'COLLECTION_SCAN',
                'COLLECTION_CREATE',
                'COLLECTION_DESTROY',
                'COLLECTION_UPDATE',
                'COLLECTION_SYNC'
            ]

    constructor: (apptools, window) ->

        ## 1: Create internal state
        @_state =

            # Runtime/opt data
            runtime:

                # Data and stat indexes
                index:
                    key_read_tally: {}
                    key_write_tally: {}
                    local_by_key: {}
                    local_by_kind: {}

                # Key/collection/kind counts
                count:
                    total_keys: 0
                    by_collection: []
                    by_kind: []

                # Local entity JSON data
                data: {}

            # Runtime configuration
            config:

                autoload: false     # trigger bootstrap (and potentially sync) on pageload
                autosync:           # automatic sync functionality (backbone integration)
                    enabled: false  # enable/disable flag (bool)
                    interval: 120   # sync interval, in seconds (int)

                drivers: []         # storage engine drivers
                engines: {}         # storage engine adapters

                encrypt: false      # enable reversible encryption
                integrity: false    # enable integrity checks
                obfuscate: false    # base64 keys before they go into storage
                local_only: false   # only store things locally in the storage API memory space

                callbacks:          # app-level hookin points
                    ready: null
                    sync: null

            # Optimization supervisor and inject bridge
            supervisor: {}
            cachebridge: {}

            # Class/model kind map
            model_kind_map: {}
            collection_kind_map: {}


        ## 2: Internal Methods
        @internal =

            check_support: (modernizr) ->
            bootstrap: (lawnchair) ->
            provision_collection: (name, adapter, callback) ->
            add_storage_engine: (name, driver, engine) =>

                try
                    # Instantiate the driver & engine
                    d = new driver(apptools)
                    e = new engine(apptools)

                catch err
                    return false

                # Check compatibility, if it even instantiated
                if e.compatible()

                    # Add to installed engines
                    @_state.config.engines[name] = e

                    # Attach engine to driver and register
                    driver.adapter = @_state.config.engines[name]
                    @_state.config.drivers.push driver

                    apptools.sys.drivers.install 'storage', name, d, d.enabled? | true, d.priority? | 50, (driver) =>
                        apptools.events.trigger 'ENGINE_LOADED', driver: driver, engine: driver.adapter

                    return true

                else
                    apptools.dev.verbose 'StorageEngine', 'Detected incompatible storage engine. Skipping.', name, driver, engine
                    return false


        ## 3: Public Methods
        @get = () =>
        @list = () =>
        @count = () =>
        @put = () =>
        @query = () =>
        @delete = () =>
        @sync = () =>


        ## 4: Runtime setup
        @_init = () =>
            apptools.events.trigger 'STORAGE_INIT'
            apptools.dev.verbose 'Storage', 'Storage support is currently under construction.'

            if apptools.sys?.preinit?.detected_storage_engines?
                for engine in apptools.sys.preinit.detected_storage_engines
                    @internal.add_storage_engine(engine.name, engine.driver, engine.adapter)

            apptools.events.trigger 'STORAGE_READY'

        ## 5: Bind/bridge events
        apptools.events.bridge ['STORAGE_READ', 'STORAGE_WRITE', 'STORAGE_DELETE'], 'STORAGE_ACTIVITY'
        apptools.events.bridge ['COLLECTION_CREATE', 'COLLECTION_UPDATE', 'COLLECTION_DESTROY', 'COLLECTION_SYNC', 'COLLECTION_SCAN'], 'STORAGE_ACTIVITY'


@__apptools_preinit.abstract_base_classes.push CoreStorageAPI
