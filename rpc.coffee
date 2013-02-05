#### === Transport Interfaces === ####
@TransportInterface = class TransportInterface extends Interface

    # Abstract interface for transport interfaces.

    capability: 'transport'
    required: []

@RPCInterface = class RPCInterface extends TransportInterface

    # JSON/XMLRPC Capability

    capability: 'rpc'
    parent: TransportInterface
    required: ['factory', 'fulfill']

    factory: () ->
    fulfill: () ->

@SocketInterface = class SocketInterface extends TransportInterface

    # WebSockets Capability

    capability: 'socket'
    parent: TransportInterface
    required: ['factory', 'open', 'send', 'close', 'message']

    open: () ->
    send: () ->
    close: () ->
    factory: () ->
    message: () ->

#### === Native Driver === ####
@NativeXHR = class NativeXHR extends CoreObject

    xhr: null
    request: null
    headers: {}
    events: {}

    constructor: (@xhr, @request) ->

        @open = (http_method, url, async) => @xhr.open(http_method, url, async)

        @get_header = (key) => return @headers[key]
        @set_header = (key, value) => @headers[key] = value

        @send = (payload) =>

            # Set headers and callbacks
            (@xhr.setRequestHeader(key, value) for key, value of @headers)
            (@xhr[name] = callback) for name, callback of @events

            return @xhr.send(payload)
        return @

@SocketState = class SocketState extends CoreObject

    # Socket States

    CLOSED = 1  # Socket hasn't been opened, or has been closed.
    OPEN = 2  # Socket is currently open and live.
    SLEEP = 3  # Socket has requested minimal activity.
    ERROR = 4  # Socket has encountered an error.

@SocketCommands = class SocketCommands extends CoreObject

    # Socket Commands

    PING = 0  # Request a 'PONG'.
    PONG = 1  # Respond to a 'PING'.
    INIT = 2  # Initialize a new socket connection.
    AUTH = 3  # Request/provide auth credentials.
    DENY = 4  # Indicate authentication/authorization was denied.
    WAIT = 5  # Wait for a deferred push response.
    SYNC = 6  # Synchronize a targeted bundle.
    CLOSE = 7  # Indicate that one party would like the connection closed.
    ALLOW = 8  # Indicate authentication/authorization was granted.
    NOTIFY = 9  # Notify server/client of activity on a channel/request.
    REQUEST = 10  # Request a response for a Remote Procedure Call.
    RESPONSE = 11  # Respond to a request for a Remote Procedure Call.
    PUBLISH = 12  # Publish to a named channel.
    SUBSCRIBE = 13  # Subscribe to a named channel.

@NativeSocket = class NativeSocket extends CoreObject

    # Socket Wrapper

    id: 0
    uuid: null
    name: null
    host: null
    state: SocketState.CLOSED
    config: {}
    events: {}
    socket: null
    request: null
    protocols: []

    constructor: (@config, @events={}, @socket=WebSocket) ->

        ## fn-local proxy for event callbacks
        proxy =

            open: (event) =>
                @internal.state(SocketState.OPEN)
                @events.open(event, @socket) if @events.open?

            error: (event) =>
                @internal.state(SocketState.ERROR)
                @events.error(event, @socket) if @events.error?

            message: (event) =>
                @events.message(event.data, event, @socket) if @events.message?

            close: (event) =>
                @internal.state(SocketState.CLOSED)
                @events.close(event, @socket) if @events.close?

        ## runtime internals
        @internal =

            bind: () =>

                # Bind socket event proxies

                @socket.onopen = proxy.open
                @socket.onclose = proxy.close
                @socket.onmessage = proxy.message
                @socket.onerror = proxy.error

                return @

            send: (args...) => return @socket.send(args...)
            state: (status) => return (@state = status)

    ## protocol management
    protocols: []

    add_protocol: (object) ->
        for p in @protocols
            if p.name == object.name
                $.apptools.dev.warning('fcm:socket', 'Re-registered protocol.', object)
                return @  # we already have this protocol
        @protocols.unshift(object)
        return @

    list_protocols: () ->
        return @protocols

    remove_protocols: (name) ->
        index = null
        for p, i in @protocols
            if p.name == name
                index = i
                break

        delete @protocols[i]
        return @

    open: (url=null) =>

        if !url? and !@config.host and !@config.endpoint?
            throw "Must provide a host or socket URL."
        else
            if url?
                socket = @socket = new @socket(url, (protocol.name for protocol in @protocols))
            else
                if @config.endpoint?
                    socket = @socket = new @socket(@config.endpoint, (protocol.name for protocol in @protocols))
                else
                    if @config.secure?
                        transport = if @config.secure then 'wss' else 'ws'
                    else
                        transport = 'ws'
                    socket = @socket = new @socket([transport, @config.host].join('://'), (protocol.name for protocol in @protocols))

            @internal.bind()
            return @

    establish: @::open

    close: (graceful=true) =>

        if graceful
            return @send(SocketCommands.CLOSE)
        else
            return @socket.close()

    destroy: @::open

    send: (command, data=null) =>

        if typeof command == 'number'
            return @transmit(@serialize(command, data))
        else
            if !data?
                return @transmit(command)
            else
                return @transmit(@serialize(SocketCommands[command], data))

    serialize: (command, data=null) =>

        if !_.is_array(command)
            command = [command]

        if !_.is_array(data)
            data = [data]

        cmdlist = []
        for cmd, i in command

            switch cmd

                when SocketCommands.PING then cmdlist.push 0
                when SocketCommands.PONG then cmdlist.push 1
                when SocketCommands.INIT then cmdlist.push @identify()
                when SocketCommands.REQUEST then cmdlist.push data[i].payload()
                else cmdlist.push data[i]

        return cmdlist

    set_header: (name, value) =>

        # add a persistent header
        @config.headers[name] = value
        return @

    get_header: (name) =>

        # retrieve a persistent header
        if @config.headers[name]?
            return @config.headers[name]
        else
            return false

    transmit: (body) =>

        # wrap in realtime wire format
        payload =
            id: @id++
            headers: {}
            request: body

        @payload.headers = _.extend({}, @payload.headers, @config.headers)
        return @internal.send(JSON.stringify(payload))

@SocketVocabulary = class SocketVocabulary extends CoreObject

@SocketProtocol = class SocketProtocol extends CoreObject

    # Socket Protocol

    @name = 'APTLS_V1'
    @state = SocketState
    @commands = SocketCommands
    @vocabulary = SocketVocabulary

    install: (window, i) ->
        window.__apptools_preinit.abstract_base_classes.push i
        window.NativeSocket::add_protocol(i)
        return i

    get_command: (id) ->
        for cmd, sentinel of @commands
            if id == sentinel
                return cmd

    pack: (command, frame) -> return @encode(@serialize(command, frame))
    unpack: (raw) -> return @deserialize(@decode(raw))

@RPCPromise = class RPCPromise extends CoreObject

    expected: null
    directive: null
    fulfilled: false

    constructor: (@expected, @directive) ->
        return @

    value: (block=true, autostart=false) ->
        if directive.status != 'constructed'
            if directive.status == 'pending'
                loop
                    break unless directive.status == 'pending'
                return directive.response
            else
                return @directive.response
        else
            return @directive.request.fulfill()

@ServiceLayerDriver = class ServiceLayerDriver extends Driver

    name: 'apptools'
    native: true
    interface: [
        RPCInterface
    ]

    constructor: (apptools) ->

        @internal =

            status_codes:
                errors: [400, 401, 403, 404, 405, 406, 500, 501, 502, 503, 504, 505]
                success: [200, 201, 202, 203, 204, 205, 303, 304, 301, 302, 307, 308]

            endpoint: (request) =>  # Not yet in use.

        ## NativeRPC
        @rpc =

            factory: (context) => new NativeXHR(new XMLHttpRequest(), context)

            fulfill: (xhr, request, dispatch) =>

                ## Open XHR + set headers
                xhr.open(request.context.http_method, request.endpoint(apptools.rpc.state.config.jsonrpc), request.context.async)
                (xhr.set_header(header, value) for header, value of _.extend({"Content-Type": request.context.content_type}, apptools.rpc.state.config.headers, request.context.headers))

                decode = (status, event) =>

                    try
                        response = JSON.parse(event.target.response) unless ((not event.target.response?) or (not _.is_string(event.target.response)) or (event.target.response.length < 0))
                    catch e
                        response = event.target.response

                    if _.in_array(@internal.status_codes.errors, event.target.status)
                        return dispatch('failure', response)
                    return dispatch(response.status, response)

                ## Attach XHR success callback
                load = xhr.events.onload = (event) => decode('success', event)
                failure = xhr.events.onerror = xhr.events.onabort = xhr.events.timeout = (event) => decode('failure', event)

                ## Serialize payload and send
                return xhr.send(JSON.stringify(request.payload()))
        return super apptools

@RealtimeDriver = class RealtimeDriver extends Driver

    name: 'apptools'
    native: true
    interface: [
        SocketInterface
    ]

    constructor: (apptools) ->

        @internal =

            impl: NativeSocket
            state: SocketState
            config: apptools.sys.state.config.transport.sockets

        @rpc =

            factory: (context) => return @internal.acquire(context)

            fulfill: (sock, request, dispatch) =>

                ## Grab us an available/new socket
                @rpc.factory()

            open: () =>
            send: () =>
            close: () =>
            message: () =>


#### === RPC Base Objects === ####
@RPCContext = class RPCContext extends Model

    # Represets execution context for an RPC request.

    model:
        url: String()
        async: Boolean()
        defer: Boolean()
        headers: Object()
        cacheable: Boolean()
        http_method: String()
        crossdomain: Boolean()
        content_type: String()
        ifmodified: Boolean()
        base_uri: String()

    defaults:
        async: true, defer: false, headers: {}, cacheable: false, http_method: 'POST', crossdomain: false, content_type: 'application/json', ifmodified: false

    constructor: (opts={}) -> _.extend(@, @defaults, opts)

@RPCEnvelope = class RPCEnvelope extends Model

@RequestEnvelope = class RequestEnvelope extends RPCEnvelope

    # Represents meta details about an RPC request.

    model:
        id: Number()
        opts: Object()
        agent: Object()

    constructor: (envelope) -> _.extend(@, envelope)

@ResponseEnvelope = class ResponseEnvelope extends RPCEnvelope

    # Represents meta details about an RPC response.

    model:
        id: Number()
        flags: Object()
        platform: Object()

    constructor: (envelope) -> super _.extend(@, envelope)

@RPC = class RPC extends Model

    model:
        ttl: Number()
        context: RPCContext
        envelope: RPCEnvelope

    constructor: ->
        return @state('constructed')

    expired: () -> true

    state: (state) =>
        if not @flags?
            @flags = {}
        @flags.state = state
        return @

#### === RPC Request/Response === ####
@RPCRequest = class RPCRequest extends RPC

    # Represents a single RPC request, complete with config, params, callbacks, etc

    states: ['constructed', 'pending', 'fulfilled']

    model:
        state: String()
        params: Object()
        method: String()
        service: String()

    # RPCRequest Constructor
    constructor: (object) -> super _.extend(@, object)

    # Fulfill an RPC method server-side
    fulfill: (callbacks={}) -> $.apptools.rpc.request.fulfill(@, callbacks)

    # Indicate that we'd like to defer a response to a push channel, if possible
    defer: (push) -> @flags.defer = push

    # Return a unique string representing this requests' signature, suitable for caching.
    fingerprint: => window.btoa(JSON.stringify([@service, @method, @params, @envelope.opts]))

    # Return a prepared endpoint URL.
    endpoint: (config={}) ->
        if not @context.url?
            if not config.host?
                base_host = [window.location.protocol, window.location.host].join('//')
            else
                base_host = config.host
            if @context.base_uri? and _.is_string(@context.base_uri)
                base_uri = @context.base_uri
            else
                base_uri = config.base_uri
            return [[base_host.concat(base_uri), @service].join('/'), @method].join('.')
        return @context.url

    # Format the RPC for communication
    payload: =>
        return {
            id: @envelope.id
            opts: @envelope.opts
            agent: @envelope.agent
            request:
                params: @params
                method: @method
                api: @service
        }

@RPCResponse = class RPCResponse extends RPC

    # Represents a response to an RPCRequest

    states: ['constructed', 'pending', 'success', 'failure', 'wait']

    model:
        type: String()
        status: String()
        payload: Object()

    events:
        success: null
        failure: null

    constructor: (response) -> super _.extend(@, response)
    inflate: (raw_response) => _.extend(@, raw_response)
    callbacks: (@events) -> @

@RPCErrorResponse = class RPCErrorResponse extends RPCResponse

    # Represents a response indicating an error

    model:
        code: Number()
        message: String()

    constructor: (response, raw_response) ->

        @events = response.events
        if not raw_response.response?.content?
            $.apptools.dev.error('RPC', 'Invalid RPC error structure.', response, raw_response)
            throw "Invalid RPC error structure."
        return @inflate(raw_response)

#### === RPCAPI - Service Class === ####
@RPCAPI = class RPCAPI extends CoreObject

    # Represents a server-side API, so requests can be sent/received from JavaScript

    constructor: (name, methods, config, apptools) ->

        __remote_method_proxy = (name, method, config, apptools) ->

            return (params={}, context={}, opts={}, envelope={}, request_class=RPCRequest) =>

                # Build a remote method proxy
                do (params, context, opts, envelope) =>
                    return apptools.rpc.request.factory(
                                method: method
                                service: name
                                params: params || {}
                                context: new RPCContext(_.extend(apptools.rpc.request.context.default(), context))
                                envelope: new RequestEnvelope(_.extend(envelope, id: apptools.rpc.request.provision(), opts: opts || {}, agent: apptools.agent.fingerprint)),
                                request_class)

        # Build a function to proxy shortcutted RPC requests to the main API.
        (@[method] = __remote_method_proxy(name, method, config, apptools) for method in methods) unless (not methods.length? or methods.length == 0)
        apptools.rpc.service.register(@, methods, config)
        return @

@CoreRPCAPI = class CoreRPCAPI extends CoreAPI

    # CoreRPCAPI - low-level RPC interaction API, mediates between the service layer and dispatch.

    @mount = 'rpc'
    @events = ['RPC_CREATE', 'RPC_FULFILL', 'RPC_SUCCESS', 'RPC_FAILURE', 'RPC_COMPLETE', 'RPC_PROGRESS']

    constructor: (apptools, window) ->

        ## RPCAPI State
        @state =

            # Configuration
            config:

                # HTTP Request/Response: Service-Layer based JSONRPC Services
                jsonrpc:
                    host: null
                    enabled: true
                    base_uri: '/_api/rpc'
                    default_ttl: null
                    driver: null

                # HTTP Push: AppEngine Channel-based push transport
                channel:
                    token: null
                    script: null
                    enabled: false
                    status: 'DISCONNECTED'
                    default_ttl: null
                    driver: null

                # Low-Level Bidirectional TCP: WebSockets-based push transport
                sockets:
                    host: null
                    token: null
                    enabled: false
                    status: 'DISCONNECTED'
                    default_ttl: null
                    driver: null

                headers:
                    "X-ServiceClient": ["AppToolsJS/", AppTools.version.get()].join(''),
                    "X-ServiceTransport": "AppTools/JSONRPC"

            # Holds information about the current API consumer.
            consumer: null

            # Holds runtime request information.
            requestpool:
                id: 1

                # Request Pool
                data: []
                index: []

                # Done/Pending/Error/Expected
                done: []
                queue: []
                error: []
                expect: {}
                context: new RPCContext

            # Holds runtime service information.
            servicepool:
                name_i: {}
                rpc_apis: []

            # Holds a history of all RPC interaction in the current page.
            history:
                last_request: null
                last_error: null
                last_success: null
                rpclog: []

            # In-memory cache for request/response pairs.
            cache:
                data: {}   # Holds request/response data.
                index: {}  # Holds request/response fingerprints => data mappings.

        @internals =

            validate: (rpc) => rpc

            respond: (directive, use_cache=false) =>

                apptools.events.trigger('RPC_FULFILL', directive)
                if use_cache
                    if directive.request.cacheable? and directive.request.cacheable == true
                        try
                            return @internals.validate(x) if ((x = @state.cache.data[@state.cache.index[directive.request.fingerprint()]])? and not x.expired())
                return [@internals.expect(directive, use_cache), @internals.send_rpc(directive)]

            expect: (directive, use_cache) =>

                directive.status = 'pending'
                directive.request.state('pending')
                directive.response.state('pending')

                return new RPCPromise(directive, (@state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]] = {

                    success: (response) =>

                        # Mark as `done`
                        directive.status = 'success'
                        directive.request.state('fulfilled')
                        directive.response.state('success')

                        @state.requestpool.done.push(@state.requestpool.index[directive.request.envelope.id])

                        # Remove from `queued` and `expect`
                        @state.requestpool.queue.splice(directive.queue_i, directive.queue_i)
                        delete @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]]

                        if use_cache
                            @response.store(directive.request, directive.response)

                        # Dispatch AppTools-level event and request-level success event
                        apptools.events.dispatch('RPC_SUCCESS', directive)
                        directive.response.events.success(response.response.content, response.response.type, response)
                        return

                    failure: (response) =>

                        # Mark as `failure`
                        directive.status = 'failure'
                        directive.response.state('failure')
                        directive.request.state('fulfilled')

                        @state.requestpool.error.push(@state.requestpool.index[directive.request.envelope.id])

                        # Remove from `queued` and `expect`
                        @state.requestpool.queue.splice(directive.queue_i, directive.queue_i)
                        delete @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]]

                        # Dispatch AppTools-level event and request-level failure event
                        apptools.events.dispatch('RPC_FAILURE', directive)
                        directive.response.events.failure(response.response.content, response.response.type, response)
                        return

                    progress: (event) =>

                        # Dispatch AppTools-level event and request-level event
                        apptools.events.dispatch('RPC_PROGRESS', directive)
                        directive.response.events.progress?(directive.request, event, directive)
                        return

                }))

            send_rpc: (directive) =>

                driver = @state.config.jsonrpc.driver ||= apptools.sys.drivers.resolve(RPCInterface)
                if not driver?
                    apptools.dev.error('RPC', 'Failed to resolve RPC-compatible driver for prompted RPC directive.', driver, directive)
                    throw "Failed to resolve RPC-compatible driver prompted RPC directive."

                queue_i = directive.queue_i = (@state.requestpool.queue.push(@state.requestpool.index[directive.request.envelope.id]) - 1)
                xhr = directive.xhr = driver.rpc.factory(directive.request)

                apptools.events.dispatch('RPC_FULFILL', directive.request, directive.xhr, directive)
                driver.rpc.fulfill(directive.xhr, directive.request, (status, response) => @response.dispatch(status, directive, response))

                return directive

            dispatch: (directive, raw_response) =>

                if not @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]]?
                    apptools.dev.error('RPC', 'Received a request to dispatch an unexpected RPC response.', directive)
                    throw "Unexpected RPC response."
                    return @
                return @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]][directive.response.status](directive.response, directive.response.type, raw_response)

        ## Request Tools/Methods
        @request =

            # Provision a request ID, with space in dispatch arrays laid out.
            provision: () => @state.requestpool.id++

            # Create a new RPCRequest object, from an RPCContext + RPCEnvelope and a proxied method call.
            factory: (rpc, request_class=RPCRequest) =>
                request = new request_class(rpc)
                data_i = @state.requestpool.index[request.envelope.id] = (@state.requestpool.data.push({request: request, response: new RPCResponse(id: request.envelope.id), status: 'constructed'}) - 1)
                apptools.events.dispatch('RPC_CREATE', rpc, request, data_i)
                return request

            # Fulfill an RPC by exchanging it for a response with either a cache or the Service Layer.
            fulfill: (request, callbacks={}, use_cache=false) =>
                @state.requestpool.data[@state.requestpool.index[request.envelope.id]].response.callbacks(_.extend(@response.callbacks.default, callbacks))
                return @internals.respond(@state.requestpool.data[@state.requestpool.index[request.envelope.id]], use_cache)

            context:

                # Return the default RPC execution context.
                default: (setdefault) =>
                    (@state.requestpool.context = setdefault) unless not setdefault?
                    return @state.requestpool.context

                # Create a new RPC execution context.
                factory: => new RPCContext(arguments...)

        ## Response Tools/Methods
        @response =

            store: (request, response) => @  # Response caching is currently stubbed.

            notify: (status, directive, raw_response) =>

            dispatch: (status, directive, raw_response) =>

                (directive.response = new RPCErrorResponse(directive.response, raw_response)) unless status != 'failure'
                directive.response.inflate(raw_response) unless status == 'failure'
                return @internals.dispatch(directive, raw_response)

            callbacks:

                default:

                    notify: (response) => apptools.dev.verbose('RPC', 'Encountered notify RPC with no callback.', response)
                    success: (response) => apptools.dev.verbose('RPC', 'Encountered successful RPC with no callback.', response)
                    failure: (response) => apptools.dev.verbose('RPC', 'Encountered failing RPC with no error callback.', response)

        ## Direct Dispatch
        @direct =

            notify: (payload) ->
            request: (payload) ->
            response: (payload) ->
            subscribe: (payload) ->
            broadcast: (payload) ->

        ## Service Tools
        @service =

            # Factory method for installing new RPCAPIs.
            factory: (name_or_apis, base_uri, methods, config) =>

                (name_or_apis = [name_or_apis]) unless _.is_array(name_or_apis)
                for item in name_or_apis
                    [name, methods, config] = item
                    @state.servicepool.name_i[name] = @state.servicepool.rpc_apis.push(new RPCAPI(name, methods, config, apptools)) - 1
                    apptools.api[name] = @state.servicepool.rpc_apis[@state.servicepool.name_i[name]]
                return @

            # Callback from an RPCAPI once it is done constructing itself
            register: (service, methods, config) => apptools.events.dispatch('CONSTRUCT_SERVICE', service, methods, config)

@CoreServicesAPI = class CoreServicesAPI extends CoreAPI

    ## CoreServicesAPI - sits on top of the RPCAPI to abstract server interaction

    @mount = 'api'
    @events = ['SERVICES_INIT', 'CONSTRUCT_SERVICE']

    constructor: (apptools, window) ->

        @_init = (apptools) =>

            # Check for in-page services config, and send over to the RPCAPI.
            if apptools.sys.state.config? and apptools.sys.state.config?.services?

                if apptools.sys.state.config.services.endpoint?
                    apptools.rpc.state.config.jsonrpc.host = apptools.sys.state.config.services.endpoint

                if apptools.sys.state.config.services.consumer?
                    apptools.rpc.state.config.consumer = apptools.sys.state.config.services.consumer

                apptools.events.dispatch('SERVICES_INIT', apptools.rpc.state.config)
                apptools.rpc.service.factory(apptools.sys.state.config.services.apis)
                apptools.dev.verbose('RPC', 'Autoloaded in-page RPC config.', apptools.sys.state.config.services)
            return

(i::install(window, i) for i in [TransportInterface, RPCInterface, SocketInterface, NativeSocket, SocketProtocol, NativeXHR, RPCPromise, ServiceLayerDriver])

@__apptools_preinit.abstract_base_classes.push CoreRPCAPI
@__apptools_preinit.abstract_base_classes.push CoreServicesAPI