# Dev/Debug API
class CoreDevAPI extends CoreAPI

    constructor: (apptools, window) ->

        # Setup internals
        @config = {}

        # Setup externals
        @environment = {}
        @performance = {}
        @debug =
            logging: true
            eventlog: true
            verbose: true
            serverside: false


    setDebug: (@debug) =>
        # Set debug settings (usually triggered by the server)
        console.log("[CoreDev] Debug has been set.", @debug)

    log: (module, message, context...) =>
        # Log something to the console, even when verbose is off
        if not context?
            context = '{no context}'
        if @debug.logging is true
            console.log "["+module+"] INFO: "+message, context...
        return

    error: (module, message, context...) =>
        # Log an error to the console (always ignores verbose flag)
        if @debug.logging is true
            console.log "["+module+"] ERROR: "+message, context...
        return

    verbose: (module, message, context...) =>
        # Log something to the console, but only if verbose is on
        if @debug.verbose is true
            @log(module, message, context...)
        return
