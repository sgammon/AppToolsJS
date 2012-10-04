# AppTools Init
class AppTools

    @version =
        major: 0
        minor: 1
        micro: 5
        build: 8272012 # m/d/y
        release: "BETA"
        get: () -> [[[x.toString() for x in [@major, @minor, @micro]].join('.'), @build.toString()].join('-'), @release].join(' ')

    constructor: (window)  ->

        ##### ===== 1: Core Setup ===== #####

        ## System config
        config =

            transport:
                rpc:
                    host: null
                    enabled: true
                    base_uri: '/_api/rpc'

                sockets:
                    host: null
                    enabled: false
                    endpoint: '/_api/realtime'

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
                config: {}          # Replaced with in-page config
                status: 'NOT_READY' # System status
                flags: ['base']     # System flags
                preinit: {}         # System preinit
                modules: {}         # Installed system modules
                classes: {}         # Installed AppTools-related classes
                drivers: {}         # Installed Feature/Library Drivers
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
                        for _iface in preinit.abstract_feature_interfaces
                            @sys.interfaces.install(_iface)

                    if preinit.installed_drivers?
                        for _driver in preinit.installed_drivers
                            @sys.drivers.install(_driver)

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
                        delete mountpoint[module_name]._init

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
                    @dev.verbose('Library', name + ' detected.')
                    @events.trigger('SYS_LIB_LOADED', name: name, library: library)

                    ## Trigger install callback
                    if callback?
                        callback(library, name)

                    return @lib[name.toLowerCase()] ## done!

                resolve: (name) =>

                    ## Check to see if it's in the runtime integrations list
                    name = name.toLowerCase()
                    if @lib[name.toLowerCase()]?
                        return @lib[name.toLowerCase()]

            ## Interface management
            interfaces:
                install: (adapter) =>

                    adapter = new adapter(@)

                    ## Log + trigger event
                    @dev.verbose('Interface', 'Installed "' + adapter.capability + '" interface.', adapter)

                    ## Install into state
                    if adapter.parent != null
                        if _.is_string(adapter.parent)
                            if not @sys.state.interfaces[adapter.parent]?
                                @dev.error('System', 'Encountered interface with invalid parent reference.', adapter, adapter.parent)
                                throw "Parent interface references must be valid and child interfaces must be loaded after their parents."
                            else
                                @sys.state.interfaces[adapter.parent].children[adapter.capability] = {adapter: adapter, children: {}}
                                @events.trigger('SYS_INTERFACE_LOADED', adapter: @sys.state.interfaces[adapter.parent].children[adapter.capability].adapter)
                        else
                            if not @sys.state.interfaces[adapter.parent::capability]?
                                @dev.error('System', 'Encountered interface with invalid parent reference.', adapter, adapter.parent)
                                throw "Parent interface references must be valid and child interfaces must be loaded after their parents."
                            else
                                @sys.state.interfaces[adapter.parent::capability].children[adapter.capability] = {adapter: adapter, children: {}}
                                @events.trigger('SYS_INTERFACE_LOADED', adapter: @sys.state.interfaces[adapter.parent::capability].children[adapter.capability].adapter)
                    else
                        @sys.state.interfaces[adapter.capability] = {adapter: adapter, children: {}}
                        @events.trigger('SYS_INTERFACE_LOADED', adapter: @sys.state.interfaces[adapter.capability].adapter)

                    return @sys.state.interfaces[adapter.capability]

                resolve: (iface) =>

                    if not _.is_string(iface)
                        if iface::parent?
                            spec = [iface::parent::capability, iface::capability].join('.')
                        else
                            spec = iface::capability
                    else
                        spec = String(iface).toLowerCase()

                    ## Look for it
                    n = spec.split('.')
                    if n.length > 1
                        if @sys.state.interfaces[n[0]]?.children[n[1]]?
                            return @sys.state.interfaces[n[0]]?.children[n[1]]?.adapter
                        return false

                    if @sys.state.interfaces[spec]?
                        if @sys.state.interfaces[spec]?
                            return @sys.state.interfaces[spec].adapter
                        return false

                children: (iface) =>

                    if not _.is_string(iface)
                        iface = iface.capability

                    ## Look for it
                    if iface.contains(".")
                        return false

                    if not @sys.state.interfaces[iface]?
                        @dev.error('Failed to resolve interface children for missing interface "' + iface + '".')
                        throw 'Failed to resolve interface children for missing interface "' + iface + '".'

                    return @sys.state.interfaces[iface].children

            ## Driver management
            drivers:
                install: (driver) =>

                    # See if it's already installed first
                    if not _.is_string(driver.name)
                        @dev.error('System', 'Encountered driver without a valid name.', driver, driver.name)
                        throw "Drivers must have a string name attached at `driver.name`."

                    if @sys.state.drivers[driver.name]?
                        @dev.error('System', 'Encountered a driver conflict installing "' + driver.name + '".', 'original: ', @sys.state.drivers[driver.name], 'conflict: ', driver)
                        throw "Encountered fatal driver conflict."

                    else

                        # Make sure the driver can even work
                        if (driver::native? and driver::native == true) or (driver::library? or (driver::compatible? and (driver::compatible() == true)))

                            interfaces = (@sys.interfaces.resolve(iface) for iface in driver::interface)

                            if driver::library?
                                driver = @sys.state.drivers[driver.name] = new driver(driver::library, @, window)

                            else
                                driver = @sys.state.drivers[driver.name] = new driver(@, window)

                            # Validate interfaces
                            for iface in interfaces
                                if not driver[iface.capability]?
                                    @dev.warning('System', 'Encountered driver ("' + driver.name + '") with incomplete implementation for interface "' + iface.capability + '".', iface, driver)
                                if iface.required?
                                    for method in iface.required
                                        if not driver[iface.capability][method]?
                                            @dev.error('System', 'Encountered driver ("' + driver.name + '") without required implementation method ("' + method + '") for attached interface "' + iface.capability + '".', iface, driver)
                                            throw "Encountered fatal driver validation error."
                                iface.add(driver)

                        else
                            @dev.verbose('System', 'Installed driver "' + driver.name + '" was found to be incompatible with the current environment.')
                            return false


                ## Resolve a driver by type, or type + name
                resolve: (spec, name=null) =>

                    iface = @sys.interfaces.resolve(spec)
                    return iface.resolve(name)

            ## All systems go!
            go: (apptools) =>
                apptools.dev.log('Core', 'All systems go.')
                apptools.sys.state.status = 'READY'
                apptools.events.trigger 'PLATFORM_READY', apptools
                return @

        ## Parse in-page config, if available
        cfelem = document.getElementById 'js-config'
        if cfelem?
            @sys.state.config = _.extend(config, @sys.state.config, JSON.parse(cfelem.innerText))

        if @sys.state.config.debug?
            CoreDevAPI::debug = _.extend({}, CoreDevAPI::debug, @sys.state.config.debug)

        ## Dev/Events API (for logging/debugging - only two modules instantiated manually, so we can log stuff + trigger events during init)
        @sys.modules.install CoreDevAPI, (dev) ->
            dev.verbose('CORE', 'CoreDevAPI is up and running.')

        @sys.modules.install CoreEventsAPI, (events) =>
            events.register(@sys.core_events)

        ## Consider preinit: export/catalog preinit classes & libraries
        @sys.state.preinit = window.__apptools_preinit
        @sys.state.consider_preinit(window.__apptools_preinit)

        ## Install core modules
        @sys.state.core = [
            CoreModelAPI,       # Model API
            CoreAgentAPI,       # Agent API
            CoreRPCAPI,         # RPC API
            CoreServicesAPI,    # Services API
            CoreUserAPI,        # User API
            CoreRenderAPI       # Render API
        ]

        @sys.modules.install(@sys.state.core)

        ## Install deferred modules
        if window.__apptools_preinit?.deferred_core_modules?
            for module in window.__apptools_preinit.deferred_core_modules
                if module.package?
                    @sys.modules.install(module.module, module.package)
                else
                    @sys.modules.install(module.module)

        if window.__clock?
            if @analytics?
                @dev.verbose('Analytics', 'Installing Google Analytics timings integration.')
                window.__clock.track = (timing) =>
                    [now, args] = timing
                    [category, variable, start_time, label, sample_rate] = args
                    @analytics.track.timing(category, variable, (Math.floor(now) - Math.floor(start_time)), label, sample_rate)
                    return timing

            window.__clock.clockpoint('JavaScript', 'Platform Ready', window.__clock.ts[0][0], 'AppTools', 100)

        ## 6: We're done!
        return @.sys.go @

# Export to window
window.AppTools = AppTools
window.apptools = new AppTools(window)

# Is jQuery around?
if window.jQuery?
    # Attach jQuery shortcut
    $.extend(apptools: window.apptools)

# No? I'll just let myself in.
else if window.$?
    window.$.apptools = window.apptools

else (window.$ = (x) -> return document.getElementById(x)).apptools = window.apptools