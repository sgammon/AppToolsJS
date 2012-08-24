# AppTools Init
class AppTools

    @version =
        major: 0
        minor: 1
        micro: 5
        build: 8222012 # m/d/y
        release: "BETA"
        get: () -> [[[x.toString() for x in [@major, @minor, @micro]].join('.'), @build.toString()].join('-'), @release].join(' ')

    constructor: (window)  ->

        ##### ===== 1: Core Setup ===== #####

        ## System config
        @config =
            rpc:
                base_uri: '/_api/rpc'
                host: null
                enabled: true

            sockets:
                host: null
                enabled: false

            devtools:
                debug: true
                strict: false

        ## Library shortcuts
        @lib = {}

        ## System API
        @sys =

            platform: {}       # Platform info
            version: @version  # Version info

            ## Core events to be registered immediately
            core_events: ['SYS_MODULE_LOADED', 'SYS_LIB_LOADED', 'SYS_DRIVER_LOADED', 'PLATFORM_READY']

            ## System state
            state:
                core: []            # System core modules
                status: 'NOT_READY' # System status
                flags: ['base']     # System flags
                preinit: {}         # System preinit
                modules: {}         # Installed system modules
                classes: {}         # Installed AppTools-related classes
                interfaces: {}      # Installed feature interfaces
                integrations: []    # Installed library integrations

                add_flag: (flagname) =>
                    @sys.state.flags.push flagname

                consider_preinit: (preinit) =>

                    ## Preinit: Consider classes
                    if preinit.abstract_base_classes?
                        for cls in preinit.abstract_base_classes
                            @sys.state.classes[cls.name] = cls
                            if cls.package? and @sys.state.modules[cls.package]?
                                @sys.state.modules[cls.package].classes[cls.name] = cls
                            if cls.export? and cls.export == 'private'
                                continue
                            else
                                window[cls.name] = cls

                    ## Preinit: consider library integrations
                    if preinit.deferred_library_integrations?
                        for lib in preinit.deferred_library_integrations
                            @sys.libraries.install(lib.name, lib.library)

                    ## Preinit: consider feature interfaces
                    if preinit.abstract_feature_interfaces?
                        for _interface in preinit.abstract_feature_interfaces
                            @sys.interfaces.install(_interface.name, _interface.adapter)

                    return preinit

            ## Module management
            modules:
                install: (module_or_modules, mountpoint_or_callback=null, callback=null) =>

                    ## If we're handed an array of modules, call self with each module
                    if not _.is_array(module_or_modules) or (mountpoint_or_callback? or callback?)
                        modules = [module_or_modules]
                    else
                        modules = module_or_modules

                    ## Figure out whether our second arg is a mountpoint or a callback
                    if mountpoint_or_callback?
                        if typeof mountpoint_or_callback == 'function'
                            callback = mountpoint_or_callback
                            mountpoint = null
                        else
                            mountpoint = mountpoint_or_callback

                    ## Resolve module mount point
                    if mountpoint?
                        if not @[mountpoint]?
                            @[mountpoint] = {}
                        mountpoint = @[mountpoint]
                        pass_parent = true
                    else
                        mountpoint = @
                        pass_parent = false

                    finished_modules = []
                    for module in modules

                        ## Resolve module name
                        if module.mount?
                            module_name = module.mount
                        else
                            module_name = module.name.toLowerCase()

                        ## Register any module events
                        if module.events? and @events?
                            @events.register(module.events)

                        ## Mount module
                        if not mountpoint[module_name]?
                            if pass_parent
                                target_mod = new module(@, mountpoint, window)
                                mountpoint[module_name] = target_mod
                                @sys.state.modules[module_name] = {module: target_mod, classes: {}}
                            else
                                target_mod = new module(@, window)
                                mountpoint[module_name] = target_mod
                                @sys.state.modules[module_name] = {module: target_mod, classes: {}}

                        ## Call module init callback, if there is one
                        mountpoint[module_name]._init?(@)

                        ## If dev is available, log this
                        if @dev? and @dev.verbose?
                            @dev.verbose 'ModuleLoader', 'Installed module:', target_mod, ' at mountpoint: ', mountpoint, ' under the name: ', module_name

                        ## If events are available, trigger SYS_MODULE_LOADED
                        if @events?
                            @events.trigger('SYS_MODULE_LOADED', module: target_mod, mountpoint: mountpoint)

                        ## Call our install callback, if we have one
                        if callback?
                            callback(target_mod)
                        finished_modules.push target_mod
                    return finished_modules ## done!

            ## Library management
            libraries:
                install: (name, library, callback=null) =>

                    ## Install library shortcut
                    @lib[name.toLowerCase()] = library
                    @sys.state.integrations.push name.toLowerCase()

                    ## Log + trigger event
                    @dev.verbose('LibLoader', name + ' detected.')
                    @events.trigger('SYS_LIB_LOADED', name: name, library: library)

                    ## Trigger install callback
                    if callback?
                        callback(library, name)

                    return @lib[name.toLowerCase()] ## done!

                resolve: (name) =>

                    name = name.toLowerCase()
                    ## Check to see if it's in the runtime integrations list
                    for lib in @sys.state.integrations
                        if lib != name
                            continue
                        else
                            return @lib[name.toLowerCase()]
                    return false

            ## Interface management
            interfaces:
                install: (name, adapter) =>

                    ## Log + trigger event
                    @dev.verbose('InterfaceLoader', 'Installed "' + name + '" interface.')
                    @events.trigger('SYS_INTERFACE_LOADED', name: name, adapter: adapter)

                    ## Install into state
                    @sys.state.interfaces[name] = {adapter: adapter, methods: adapter.methods}
                    return @sys.state.interfaces[name]

                resolve: (name) =>

                    ## Look for it
                    if @sys.state.interfaces[name]?
                        return @sys.state.interfaces[name]
                    else
                        return false


            ## Driver management
            drivers:
                push: {}       ## drivers that can receive pushed data from the server
                query: {}      ## drivers that can query the dom
                loader: {}     ## drivers that can load files/modules
                transport: {}  ## drivers that can fulfill RPCs
                storage: {}    ## drivers that can store data
                render: {}     ## drivers that can render data into the DOM
                animation: {}  ## drivers that can animate or tween animations

                ## Register a driver with AppToolsJS
                install: (type, name, adapter, mountpoint, enabled, priority, callback=null) =>

                    # Add the driver to its type namespace
                    @sys.drivers[type][name] = {name: name, driver: mountpoint, enabled: enabled, priority: priority, interface: adapter}

                    # Trigger install callback + loaded event
                    if callback?
                        callback(@sys.drivers[type][name].driver)
                    @events.trigger('SYS_DRIVER_LOADED', @sys.drivers[type][name])

                    return @sys.drivers[type][name] ## done!

                ## Resolve a driver by type, or type + name
                resolve: (type, name=null, strict=false) =>

                    if not @sys.drivers[type]?
                        apptools.dev.critical 'CORE', 'Unkown driver type "' + type + '".'
                        return
                    else
                        if name?
                            if @sys.drivers[type][name]?
                                return @sys.drivers[type][name].driver
                            else
                                if strict
                                    apptools.dev.critical 'CORE', 'Could not resolve driver ', name, ' of type ', type, '.'
                            return false

                    priority_state = -1
                    selected_driver = false
                    for driver of @sys.drivers[type]

                        driver = @sys.drivers[type][driver]
                        if driver.priority > priority_state
                            selected_driver = driver
                            break
                    return selected_driver

            ## All systems go!
            go: (apptools) =>
                apptools.dev.log('Core', 'All systems go.')
                apptools.sys.state.status = 'READY'
                apptools.events.trigger 'PLATFORM_READY', apptools
                return @

        ## Dev/Events API (for logging/debugging - only two modules instantiated manually, so we can log stuff + trigger events during init)
        @sys.modules.install CoreDevAPI, (dev) ->
            dev.verbose('CORE', 'CoreDevAPI is up and running.')

        @sys.modules.install CoreEventsAPI, (events) =>
            events.register(@sys.core_events)

        ## Consider preinit: export/catalog preinit classes & libraries
        if window.__apptools_preinit?
            @sys.state.preinit = window.__apptools_preinit
            @sys.state.consider_preinit(window.__apptools_preinit)


        ##### ===== 2: Library Detection ===== #####

        ## Round 1) Feature Detection/Loader Libraries

        # 1.1 - Modernizr
        if window.Modernizr?
            @sys.libraries.install 'Modernizr', window.Modernizr, (lib, name) =>
                @load = (fragments...) =>
                    return @lib.modernizr.load fragments...

        # 1.2 - YepNope
        if window.yepnope?
            @sys.libraries.install 'YepNope', window.yepnope, (lib, name) =>
                @load = (fragments...) =>
                    return @lib.yepnope.load fragments...


        ## Round 2) Selection (Query) Engine Libraries

        # 2.1 - jQuery
        if window.jQuery?
            @sys.libraries.install 'jQuery', window.jQuery, (lib, name) =>
                @sys.drivers.install 'query', 'jquery', @sys.state.classes.QueryDriver, @lib.jquery, true, 100, null
                @sys.drivers.install 'transport', 'jquery', @sys.state.classes.RPCDriver, @lib.jquery, true, 100, null
                @sys.drivers.install 'animation', 'jquery', @sys.state.classes.AnimationDriver, @lib.jquery, true, 100, null

        # 2.2 - Zepto
        if window.Zepto?
            @sys.libraries.install 'Zepto', window.Zepto, (lib, name) =>
                @sys.drivers.install 'query', 'zepto', @sys.state.classes.QueryDriver, @lib.zepto, true, 500, null
                @sys.drivers.install 'transport', 'zepto', @sys.state.classes.RPCDriver, @lib.zepto, true, 500, null
                @sys.drivers.install 'animation', 'zepto', @sys.state.classes.AnimationDriver, @lib.zepto, true, 500, null


        ## Round 3) Render/ Animation Libraries

        # 3.1 - d3
        if window.d3?
            @sys.libraries.install 'd3', window.d3, (lib, name) =>
                @sys.drivers.install 'query', 'd3', @sys.state.classes.QueryDriver, @lib.d3, true, 800, null
                @sys.drivers.install 'transport', 'd3', @sys.state.classes.RPCDriver, @lib.d3, true, 500, null

        # 3.2 - Jacked
        if window.Jacked?
            @sys.libraries.install 'Jacked', window.Jacked, (lib, name) =>
                @sys.drivers.install 'animation', 'jacked', @sys.state.classes.AnimationDriver, @lib.jacked, true, 800, (jacked) =>
                    @dev.verbose 'Jacked', 'JackedJS detected. Installing animation support.', jacked

                    @animate = (args...) ->
                        return jacked.tween args...

                    window.HTMLElement::animate = (to, sets) ->
                        return @jacked(to, sets)

        # 3.3 - t.coffee (template rendering)
        if window.t?
            @sys.libraries.install 't', window.t, (library) =>
                @sys.drivers.install 'render', 't', @sys.state.classes.RenderDriver, @lib.t, true, 1000, (t) =>
                    @dev.verbose 't', 'Native template render driver "t" loaded.'

        # 3.4 - Mustache
        if window.Mustache?
            @sys.libraries.install 'Mustache', window.Mustache, (library) =>
                @sys.drivers.register 'render', 'mustache', @sys.state.classes.RenderDriver, @lib.mustache, true, 500, (mustache) =>
                    @dev.verbose 'Mustache', 'Render support is currently stubbed. Come back later.'


        ##### ===== 3: Install Core Modules ===== #####
        @sys.state.core = [
            CoreModelAPI,       # Model API
            CoreAgentAPI,       # Agent API
            CoreDispatchAPI,    # Dispatch API
            CoreRPCAPI,         # RPC API
            CorePushAPI,        # Push API
            CoreUserAPI,        # User API
            CoreStorageAPI,     # Storage API
            CoreRenderAPI       # Render API
        ]

        @sys.modules.install(@sys.state.core)


        ##### ===== 4: Install Deferred Modules ===== #####
        if window.__apptools_preinit?.deferred_core_modules?
            for module in window.__apptools_preinit.deferred_core_modules
                if module.package?
                    @sys.modules.install(module.module, module.package)
                else
                    @sys.modules.install(module.module)

        ## 5: We're done!
        return @.sys.go @

# Export to window
window.AppTools = AppTools
window.apptools = new AppTools(window)

# Is jQuery around?
if window.jQuery?
    # Attach jQuery shortcut
    $.extend(apptools: window.apptools)

# No? I'll just let myself in.
else
    # Attach jQuery shim
    window.$ = (id) -> document.getElementById(id)
    window.$.apptools = window.apptools