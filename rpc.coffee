
#### === Transport Interfaces === ####
class TransportInterface extends Interface

    # Abstract interface for transport interfaces.

    capability: 'transport'
    required: []

class RPCInterface extends TransportInterface

    # JSON/XMLRPC Capability

    capability: 'rpc'
    required: []

class PushInterface extends TransportInterface

    # Channel/Comet Capability

    capability: 'push'
    required: []

class SocketInterface extends TransportInterface

    # WebSockets (Bi-Directional) Capability

    capability: 'socket'
    required: []

(i::install(window, i) for i in [TransportInterface, RPCInterface, PushInterface, SocketInterface])


#### === RPC Base Objects === ####
class RPCContext extends Model

    # Represets execution context for an RPC request.

    model:
        async: true
        defer: false
        cacheable: true
        http_method: 'POST'
        crossdomain: false
        content_type: 'application/json'
        ifmodified: false

class RPCEnvelope extends Model

class RequestEnvelope extends RPCEnvelope

    # Represents meta details about an RPC request.

    model:
        opts: Object()
        agent: Object()

    constructor: (envelope) ->

        # Provision an ID, splice it in, and pass the call up the super chain.
        super _.extend(@, envelope)

class ResponseEnvelope extends RPCEnvelope

    # Represents meta details about an RPC response.

    model:
        flags: Object()
        platform: Object()

    constructor: (envelope) ->

        # Fill out a response envelope, given a native response object.
        super _.extend(@, envelope)

class RPC extends Model

    model:
        id: Number()
        context: RPCContext
        envelope: RPCEnvelope


#### === RPC Request/Response === ####
class RPCRequest extends RPC

    # Represents a single RPC request, complete with config, params, callbacks, etc

    model:
        args: Object()
        action: String()
        method: String()
        service: String()
        base_uri: String()

    # RPCRequest Constructor
    constructor: (object) ->

        _.extend(@, object)

    # Fulfill an RPC method server-side
    fulfill: (callbacks={}, config) ->

        ## fulfill request
        return @

    # Indicate that we'd like to defer a response to a push channel, if possible
    defer: (push) ->

        ## set deferred mode
        return @

    # Format the RPC for communication
    payload: ->
        _payload =
            id: @envelope.id
            opts: @envelope.opts
            agent: @envelope.agent
            request:
                params: @params
                method: @method
                api: @api

        return _payload

class RPCResponse extends RPC

    # Represents a response to an RPCRequest

    model:
        type: String()
        status: String()
        payload: Object()

    constructor: (response) ->
        super _.extend(@, response)

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

            return (params={}, context={}, opts={}, envelope={}) =>

                # Build a remote method proxy
                do (params, context, opts, envelope) =>
                    request_id = apptools.rpc.request.provision()
                    return apptools.rpc.request.factory(
                                method: method
                                service: name
                                params: params || {}
                                context: new RPCContext(_.extend(apptools.rpc.request.context.default(), context))
                                envelope: new RequestEnvelope(_.extend(envelope, id: request_id, opts: opts || {}, agent: apptools.agent.fingerprint)))

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

                # HTTP Push: AppEngine Channel-based push transport
                channel:
                    token: null
                    script: null
                    enabled: false
                    status: 'DISCONNECTED'

                # Low-Level Bidirectional TCP: WebSockets-based push transport
                sockets:
                    host: null
                    token: null
                    enabled: false
                    status: 'DISCONNECTED'

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
                done: []
                queue: []
                index: []
                expected: {}
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

        @internals =

            respond: (request) =>

                ## CHECK REQUEST FOR CACHEABILITY
                ## CHECK CACHE FOR RESPONSE
                ## --IF FOUND, VALIDATE AGAINST TTL
                ## ----IF VALID, SKIP SEND AND DISPATCH
                ## OTHERWISE, SEND_RPC

            send_rpc: (request) =>

                ## MOVE REQUEST TO QUEUED STATUS
                ## RESOLVE DRIVER TO SEND
                ## PASS TO DRIVER WITH CONTEXT
                ## RETURN RPC FUTURE

            expect: (response) =>

                ## REGISTER EMPTY RESPONSE WITH EXPECTED PUSH DISPATCH

            dispatch: (request, raw_response) =>

                ## POPULATE RESPONSE WITH NATIVE OBJECT
                ## DISPATCH SUCCESS() OR FAILURE() CALLBACKS

        ## Request Tools/Methods
        @request =

            # Provision a request ID, with space in dispatch arrays laid out.
            provision: () =>
                id = @state.next_id
                @state.next_id++
                return id

            # Create a new RPCRequest object, from an RPCContext + RPCEnvelope and a proxied method call.
            factory: (rpc) =>
                request = new RPCRequest(rpc)
                @state.requestpool.index[request.envelope.id] = {request: request, response: new RPCResponse(id: request.envelope.id)}
                return request

            # Fulfill an RPC by exchanging it for a response with either a cache or the Service Layer.
            fulfill: (request, callbacks) =>
                return @internals.respond(@state.requestpool.index[request.envelope.id].response.callbacks(_.extend({}, apptools.rpc.response.callbacks.default(), callbacks)))

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

            store: (response) =>

                ## SERIALIZE PAYLOAD
                ## GENERATE CACHEKEY
                ## STORE VIA STORAGE

            dispatch: (response) =>

                ## RECEIVE CALLBACK FROM DRIVER
                ## RESOLVE REQUEST WITH ID

                return @internals.dispatch(request, response)


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


        ## Init: provision default context and look for RPC config
        @_init = (apptools) =>
            return @

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
