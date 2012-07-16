# Model API
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

    validate: (object, class=object::model, safe=false) =>

        if object?

            if safe
                results = {}
                check = (k, v) =>
                    results[k] = v if class[k] and v? is class[k]? and v.constructor.name is class[k].constructor.name

            else
                results = []
                check = (k, v) =>
                    results.push(k:v) if not class[k] or v? isnt class[k]? or v.constructor.name isnt class[k].constructor.name

            check(key, value) for own key, value of object

            return results if safe
            return true if results.length is 0
            throw new ModelException(@constructor.name, 'Invalid model schema on '+object.constructor.name+' object.', results)

        else throw new ModelException(@constructor.name, 'No object passed to validate().')


    ###

    # methods are placeholders for now :)
    constructor: () ->

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
