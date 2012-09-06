
#### === Transport Interfaces === ####
class TransportInterface extends Interface

    # Abstract interface for transport interfaces.

    capability: 'transport'
    required: []

window.TransportInterface = TransportInterface

class RPCInterface extends TransportInterface

    # JSON/XMLRPC Capability

    capability: 'rpc'
    parent: TransportInterface
    required: ['factory', 'fulfill']

    factory: () ->
    fulfill: () ->

window.RPCInterface = RPCInterface

class PushInterface extends TransportInterface

    # Channel/Comet Capability

    capability: 'push'
    parent: TransportInterface
    required: []

window.PushInterface = PushInterface

class SocketInterface extends TransportInterface

    # WebSockets (Bi-Directional) Capability

    capability: 'socket'
    parent: TransportInterface
    required: []

window.SocketInterface = SocketInterface

(i::install(window, i) for i in [TransportInterface, RPCInterface, PushInterface, SocketInterface])

#### === Native Driver === ####
class NativeXHR extends CoreObject

    xhr: null
    request: null
    headers: {}
    events: {}

    constructor: (@xhr, @request) ->

        @open = (http_method, url, async) =>

            # Proxy to the XHR object
            @xhr.open(http_method, url, async)

        @set_header = (key, value) =>

            # Set headers locally to keep track, then proxy
            @headers[key] = value
            @xhr.setRequestHeader(key, value)
            return @

        @get_header = (key) =>

            # Return a set header
            return @headers[key]

        @send = (payload) =>

            # Hook up the bound events, send with payload
            for name, callback of @events
                @xhr[name] = callback

            # Send it, baby!
            @xhr.send(payload)

        return @

window.NativeXHR = NativeXHR

class RPCPromise extends CoreObject

    expected: null
    directive: null
    fulfilled: false

    constructor: (@expected, @directive) ->
        return @

window.RPCPromise = RPCPromise

class ServiceLayerDriver extends Driver

    name: 'apptools'
    native: true
    interface: [
        RPCInterface,
        PushInterface
    ]

    constructor: (apptools) ->

        @internal =

            endpoint: (request) =>

        ## NativeRPC
        @rpc =
            factory: (context) =>

                return new NativeXHR(new XMLHttpRequest(), context)

            fulfill: (xhr, request, dispatch) =>

                ## Open XHR
                xhr.open(request.context.http_method, request.endpoint(apptools.rpc.state.config.jsonrpc), request.context.async)

                ## Set headers for XHR RPC interaction
                xhr.set_header("Content-Type", request.context.content_type)
                for header, value of _.extend({}, request.context.headers, apptools.rpc.state.config.headers)
                    xhr.set_header(header, value)

                ## Prepare decode function
                decode_and_dispatch = (status, event) ->
                    if _.is_string(event.target.response)
                        response = JSON.parse(event.target.response)
                    else
                        response = event.target.response

                    return dispatch(status, response)

                ## Attach XHR success callback
                load = xhr.events.onload = (event) =>

                    for http_status in [400, 401, 403, 404, 405, 500]
                        if http_status == event.target.status
                            return decode_and_dispatch('failure', event)
                    return decode_and_dispatch('success', event)

                ## Attach XHR progress callbacks
                progress = xhr.events.onprogress = xhr.events.onloadstart = xhr.events.onloadend = (event) =>

                ## Attach XHR failure callbacks
                failure = xhr.events.onerror = xhr.events.onabort = xhr.events.timeout = (event) =>

                    return decode_and_dispatch('failure', event)

                return xhr.send(JSON.stringify(request.payload()))
        super apptools
        return @

window.ServiceLayerDriver = ServiceLayerDriver::install(window, ServiceLayerDriver)

#### === RPC Base Objects === ####
class RPCContext extends Model

    # Represets execution context for an RPC request.

    model:
        url: String()
        async: true
        defer: false
        headers: {}
        cacheable: false
        http_method: String()
        crossdomain: false
        content_type: String()
        ifmodified: false
        base_uri: String()

    constructor: (opts) ->
        return _.extend(@,
            {async: true, cacheable: false, http_method: 'POST', crossdomain: false, content_type: 'application/json', ifmodified: false}, opts)

class RPCEnvelope extends Model

class RequestEnvelope extends RPCEnvelope

    # Represents meta details about an RPC request.

    model:
        id: Number()
        opts: Object()
        agent: Object()

    constructor: (envelope) ->

        # Provision an ID, splice it in, and pass the call up the super chain.
        _.extend(@, envelope)

class ResponseEnvelope extends RPCEnvelope

    # Represents meta details about an RPC response.

    model:
        id: Number()
        flags: Object()
        platform: Object()

    constructor: (envelope) ->

        # Fill out a response envelope, given a native response object.
        if not envelope.id?
            envelope.id = $.apptools.rpc.request.provision()
        super _.extend(@, envelope)

class RPC extends Model

    model:
        ttl: Number()
        context: RPCContext
        envelope: RPCEnvelope

    expired: () -> true

#### === RPC Request/Response === ####
class RPCRequest extends RPC

    # Represents a single RPC request, complete with config, params, callbacks, etc

    model:
        params: Object()
        method: String()
        service: String()

    # RPCRequest Constructor
    constructor: (object) ->

        _.extend(@, object)

    # Fulfill an RPC method server-side
    fulfill: (callbacks={}) ->

        ## fulfill request
        return $.apptools.rpc.request.fulfill(@, callbacks)

    # Indicate that we'd like to defer a response to a push channel, if possible
    defer: (push) ->

        ## set deferred mode
        return @

    # Return a unique string representing this requests' signature, suitable for caching.
    fingerprint: () ->

    # Return a prepared endpoint URL.
    endpoint: (config) ->
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
    payload: ->
        return {
            id: @envelope.id
            opts: @envelope.opts
            agent: @envelope.agent
            request:
                params: @params
                method: @method
                api: @service
        }

class RPCResponse extends RPC

    # Represents a response to an RPCRequest

    model:
        type: String()
        status: String()
        payload: Object()

    events:
        success: null
        failure: null

    constructor: (response) ->
        super _.extend(@, response)

    callbacks: (@events) -> @

    inflate: (raw_response) ->
        _.extend(@, raw_response)

class RPCErrorResponse extends RPCResponse

    # Represents a response indicating an error

    model:
        code: Number()
        message: String()

#### === RPCAPI - Service Class === ####
class RPCAPI extends CoreObject

    # Represents a server-side API, so requests can be sent/received from JavaScript

    constructor: (name, methods, config, apptools) ->

        __remote_method_proxy = (name, method, config, apptools) ->

            return (params={}, context={}, opts={}, envelope={}, request_class=RPCRequest) =>

                # Build a remote method proxy
                do (params, context, opts, envelope) =>
                    request_id = apptools.rpc.request.provision()
                    return apptools.rpc.request.factory(
                                method: method
                                service: name
                                params: params || {}
                                context: new RPCContext(_.extend(apptools.rpc.request.context.default(), context))
                                envelope: new RequestEnvelope(_.extend(envelope, id: request_id, opts: opts || {}, agent: apptools.agent.fingerprint)),
                                request_class)

        # Build a function to proxy shortcutted RPC requests to the main API.
        if methods.length > 0
            @[method] = __remote_method_proxy(name, method, config, apptools) for method in methods
        apptools.rpc.service.register(name, methods, config)
        return

class CoreRPCAPI extends CoreAPI

    # CoreRPCAPI - kicks off RPC's and mediates with dispatch

    @mount = 'rpc'
    @events = [

        'RPC_CREATE',
        'RPC_FULFILL',
        'RPC_SUCCESS',
        'RPC_ERROR',
        'RPC_COMPLETE',
        'RPC_PROGRESS'

    ]

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
                    "X-ServiceClient": ["AppToolsJS/", [
                                                AppTools.version.major.toString(),
                                                AppTools.version.minor.toString(),
                                                AppTools.version.micro.toString(),
                                                AppTools.version.build.toString()].join('.'),
                                         "-", AppTools.version.release.toString()].join(''),

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

            validate: (rpc) =>

            respond: (directive, use_cache=false) =>

                if use_cache
                    if directive.request.cacheable? and directive.request.cacheable == true
                        try
                            return @internals.validate(x) if ((x = @state.cache.data[@state.cache.index[directive.request.fingerprint()]])? and not x.expired())

                promise = @internals.expect(directive, use_cache)
                return [promise, @internals.send_rpc(directive)]

            expect: (directive, use_cache) =>

                directive.status = 'pending'
                return new RPCPromise(directive, (@state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]] = {

                    success: (response) =>

                        # Mark as `done`
                        directive.status = 'success'
                        @state.requestpool.done.push(@state.requestpool.index[directive.request.envelope.id])

                        # Remove from `queued` and `expect`
                        @state.requestpool.queue.splice(directive.queue_i, directive.queue_i)
                        delete @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]]

                        if use_cache
                            @response.store(directive.request, directive.response)

                        # Dispatch request success event
                        directive.response.events.success(response.response.content, response.response.type, response)
                        return

                    failure: (response) =>

                        # Mark as `failure`
                        directive.status = 'failure'
                        @state.requestpool.error.push(@state.requestpool.index[directive.request.envelope.id])

                        # Remove from `queued` and `expect`
                        @state.requestpool.queue.splice(directive.queue_i, directive.queue_i)
                        delete @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]]

                        # Dispatch request failure event
                        directive.response.events.failure(response.response.content, response.response.type, response)
                        return

                }))

            send_rpc: (directive) =>

                driver = @state.config.jsonrpc.driver ||= apptools.sys.drivers.resolve(RPCInterface)
                if not driver?
                    apptools.dev.error('RPC', 'Failed to resolve RPC-compatible driver for prompted RPC directive.', driver, directive)
                    throw "Failed to resolve RPC-compatible driver prompted RPC directive."

                queue_i = directive.queue_i = (@state.requestpool.queue.push(@state.requestpool.index[directive.request.envelope.id]) - 1)
                xhr = directive.xhr = driver.rpc.factory(directive.request)
                driver.rpc.fulfill(directive.xhr, directive.request, (status, response) => @response.dispatch(status, directive, response))

                return directive

            dispatch: (directive, raw_response) =>

                if not @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]]?
                    apptools.dev.error('RPC', 'Received a request to dispatch an unexpected RPC response.', directive)
                    throw "Unexpected RPC response."
                else
                    # Dispatch request-level callback
                    @state.requestpool.expect[@state.requestpool.index[directive.request.envelope.id]][directive.response.status](directive.response, directive.response.type, raw_response)
                return @

        ## Request Tools/Methods
        @request =

            # Provision a request ID, with space in dispatch arrays laid out.
            provision: () =>
                id = @state.requestpool.id
                @state.requestpool.id++
                return id

            # Create a new RPCRequest object, from an RPCContext + RPCEnvelope and a proxied method call.
            factory: (rpc, request_class=RPCRequest) =>
                request = new request_class(rpc)
                @state.requestpool.index[request.envelope.id] = (@state.requestpool.data.push({request: request, response: new RPCResponse(id: request.envelope.id), status: 'constructed'}) - 1)
                return request

            # Fulfill an RPC by exchanging it for a response with either a cache or the Service Layer.
            fulfill: (request, callbacks={}, use_cache=false) =>
                @state.requestpool.data[@state.requestpool.index[request.envelope.id]].response.callbacks(_.extend(@response.callbacks.default, callbacks))
                return @internals.respond(@state.requestpool.data[@state.requestpool.index[request.envelope.id]], use_cache)

            context:

                # Return the default RPC execution context.
                default: (setdefault) =>
                    if setdefault?
                        @state.requestpool.context = setdefault
                    return @state.requestpool.context

                # Create a new RPC execution context.
                factory: (args...) =>
                    return new RPCContext(args...)

        ## Response Tools/Methods
        @response =

            store: (request, response) =>

                apptools.dev.verbose('RPC', 'Response caching is currently stubbed.', request, response)
                return @

            dispatch: (status, directive, raw_response) =>

                if status == 'failure'
                    directive.response = new RPCErrorResponse()
                directive.response.inflate(raw_response)
                return @internals.dispatch(directive, raw_response)

            callbacks:

                default:

                    success: (response) => apptools.dev.verbose('RPC', 'Encountered successful RPC with no callback.', response)
                    failure: (response) => apptools.dev.verbose('RPC', 'Encountered failing RPC with no error callback.', response)


        ## Service Tools
        @service =

            # Factory method for installing new RPCAPIs.
            factory: (name_or_apis, base_uri, methods, config) =>

                if not _.is_array(name_or_apis)
                    name_or_apis = [name_or_apis]

                for item in name_or_apis

                    [name, methods, config] = item

                    # Construct new RPCAPI and append to state
                    rpcapi = new RPCAPI(name, methods, config, apptools)
                    pool_i = (@state.servicepool.rpc_apis.push(rpcapi) - 1)
                    @state.servicepool.name_i[name] = @state.servicepool.rpc_apis[pool_i]

                    # Proxy getter on CoreServicesAPI to the RPCAPI we're working with
                    apptools.api[name] = @state.servicepool.rpc_apis[pool_i]

                return @

            # Callback from an RPCAPI once it is done constructing itself
            register: (service, methods, config) =>

class CoreServicesAPI extends CoreAPI

    ## CoreServicesAPI - sits on top of the RPCAPI to abstract server interaction

    @mount = 'api'
    @events = [

        'SERVICES_INIT',
        'CONSTRUCT_SERVICE'

    ]

    constructor: (apptools, window) ->

        @_init = (apptools) =>

            # Check for in-page services config, and send over to the RPCAPI.
            if apptools.sys.state.config? and apptools.sys.state.config?.services?

                if apptools.sys.state.config.services.endpoint?
                    apptools.rpc.state.config.jsonrpc.host = apptools.sys.state.config.services.endpoint

                if apptools.sys.state.config.services.consumer?
                    apptools.rpc.state.config.consumer = apptools.sys.state.config.services.consumer

                apptools.rpc.service.factory(apptools.sys.state.config.services.apis)
                apptools.dev.verbose('RPC', 'Autoloaded in-page RPC config.', apptools.sys.state.config.services)
            return