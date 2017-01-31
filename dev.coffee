# Dev/Debug API
class CoreDevAPI extends CoreAPI

    debug:
        strict: false
        logging: true
        eventlog: false
        verbose: true
        serverside: false

    @mount = 'dev'
    @events = []

    constructor: (apptools, window) ->

        _sendLog = (args...) =>
            console.log(args...)

        _sendError = (args...) =>
            console.error(args...)

        _sendWarning = (args...) =>
            console.warn(args...)

        @eventlog = (operation, message, context...) =>
            # Only log if eventlogging is on
            if CoreDevAPI::debug.eventlog
                # Only log triggers and registrations if system-wide debug is on
                if operation.toLowerCase() in ['bridge', 'register', 'hook']
                    if CoreDevAPI::debug.verbose != true
                        return
                @log ['Events', operation].join(':'), message, context...
            return

        @log = (module, message, context...) =>
            # Log something to the console, even when verbose is off (but not when logging is off)
            if not context?
                context = '{no context}'
            if CoreDevAPI::debug.logging is true
                _sendLog "["+module+"] INFO: "+message, context...
            return

        @warning = @warn = (module, message, context...) =>
            # Log a warning to the console, even when verbose is off (but not when logging is off)
            if not context?
                context = '{no context}'
            if CoreDevAPI::debug.logging is true
                _sendWarning "[" + module + "] WARNING: "+message, context...
            return

        @error = (module, message, context...) =>
            # Log an error to the console (always ignores verbose flag)
            if CoreDevAPI::debug.logging is true
                _sendError "["+module+"] ERROR: "+message, context...
            return

        @verbose = (module, message, context...) =>
            # Log something to the console, but only if verbose is on
            if CoreDevAPI::debug.verbose is true
                _sendLog "["+module+"] DEBUG: "+message, context...
            return

        @exception = @critical = (module, message, exception=window.AppToolsException, context...) =>
            # Log an error and throw an exception
            _sendLog "A critical error or unhandled exception occurred."
            _sendLog "[" + module + "] CRITICAL: "+message, context...
            throw new exception(module, message, context)

        if apptools.sys.state.config.devtools.debug == true
            CoreDevAPI::debug.logging = true
            CoreDevAPI::debug.verbose = true
            if apptools.sys.state.config.devtools.strict?
                CoreDevAPI::debug.strict = apptools.sys.state.config.devtools.strict


@__apptools_preinit.abstract_base_classes.push CoreDevAPI
