# Model API
class ModelException extends Error

    constructor: (@source, @message) ->

    toString: () ->
        return '[' + @source + '] ModelException: ' + @message

class CoreModelAPI extends CoreAPI

    @mount = 'model'
    @events = []

    constructor: () ->

        # internal methods
        @internal =

            block: (async_method, params...) =>
                _done = false
                results = null

                async_method params..., (r) =>
                    results = r
                    return _done = true
                loop
                    break unless _done is false     # ...why do you want to block so BADLY? :(

                return results                      # enjoy your lukewarm results, i guess


        # sync storage methods
        @put = (object) => @internal.block(@put_async, object)
        @get = (key, kind) => @internal.block(@get_async, key, kind)
        @delete = (key, kind) =>  @internal.block(@delete_async, key, kind)

        # async storage methods
        @put_async = (callback=(x)->return x) =>
            return apptools.storage.put(@constructor::name, callback)       # these are tentative until sam finalizes storage API

        @get_async = (key, callback=(x)->return x) =>
            return apptools.storage.get(@key, @constructor::name, callback)

        @delete_async = (callback=(x)->return x) =>
            return apptools.storage.delete(@key, @constructor::name, callback)

        @all = (callback) =>
            if not callback? or not Util?.is_function(callback)
                if callback?
                    throw 'Provided callback isn\'t a function. Whoops.'
                else
                    throw 'all() requires a callback.'
            else
                # here's whatever actually happens when this is done. stubbed!
                throw 'all() currently in active development, sorry.'

        # other methods
        @register = () =>
            # registers a new model kind
            apptools.dev.verbose 'CoreModelAPI', 'register() currently in active development, sorry.'

    @init = () ->


class Model

    log: (source, message) =>

        if message?
            if $.apptools?
                return $.apptools.dev.verbose(source, message)

            else
                return console.log('['+source+']', message)

        else if source?
            message = source
            source = @constructor.name
            
            return @log(source, message)

        else
            return @log('Model', 'No message passed to log(). (You get a log message anyway <3)')

    validate: (object, cls=object.constructor::model, safe=false) =>

        if object?

            if safe
                results = {}
                check = (k, v) =>
                    results[k] = v if cls[k]? and v? is cls[k]? and v.constructor.name is cls[k].constructor.name

            else
                results = []
                check = (k, v) =>
                    results.push(k:v) if not cls[k]? or v? isnt cls[k]? or v.constructor.name isnt cls[k].constructor.name

            check(key, value) for own key, value of object

            return results if safe
            return results.length is 0

        else throw new ModelException(@constructor.name, 'No object passed to validate().')

    from_message: (object, message={}, strict=false) =>

        if object?

            cached_obj = object

            @log('Validating incoming RPC update...')

            if @validate(message, object.constructor::model)
                object[prop] = val for own prop, val of message
                @log('Valid model matched. Returning updated object...')
                return object

            else
                @log('Strict validation failed.')

                if not strict
                    @log('Nonstrict validation allowed, trying modelsafe conversion...')
                    
                    modsafe = @validate(message, object.constructor::model, true)
                        
                    if Util.is_empty_object(modsafe)
                        @log('No modelsafe properties found, canceling update...')
                        return cached_obj

                    else
                        object[p] = v for own p, v of modsafe
                        @log('Modelsafe conversion succeeded! Returning updated object...')

                        return object
                        
                else
                    @log('Strict validation only, canceling update...')
                    return cached_obj
            
        else throw new ModelException(@constructor.name, 'No object passed to from_message().')

    to_message: (object) =>

        if object?
            message = {}
            (message[prop] = val if object.constructor::model[prop]? and typeof val isnt 'function') for own prop, val of object
            
            return message

        else throw new ModelException(@constructor.name, 'No object passed to to_message().')

    constructor: (key) ->
        
        if Util.is_raw_object(key)
            @[prop] = val for prop, val of key
        else
            @key = key
        @from_message = (message, strict) => return @constructor::from_message(@, message, strict)
        @to_message = () => return @constructor::to_message(@)
        @log = (message) => return @constructor::log(@constructor.name, message)

            

    ###

    # methods are placeholders for now :)

    # synchronous methods
    put: (args...) => $.apptools.model.put(@, args...)
    get: (args...) => $.apptools.model.get(@, args...)
    delete: (args...) => $.apptools.model.delete(@, args...)

    # asynchronous methods - tentative until params finalized
    put_async: (args...) => $.apptools.model.put_async(@, args...)
    get_async: (args...) => $.apptools.model.get_async(@, args...)
    delete_async: (args...) => $.apptools.model.delete_async(@, args...)

    all: (args...) => $.apptools.model.all(@, args...)

    render: (template) =>

    ###



@__apptools_preinit.abstract_base_classes.push CoreModelAPI
@__apptools_preinit.abstract_base_classes.push Model
