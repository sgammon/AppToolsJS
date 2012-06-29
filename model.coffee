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

            validate: (model, _model=model.constructor::) ->

                invalid = []

                for prop of model
                    continue if not {}.hasOwnProperty.call(model, prop)
                    continue if model[prop].constructor.name is _model[prop].constructor.name
                    invalid.push prop

                return invalid for item in invalid
                return true

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

    key: null

    # methods are placeholders for now :)
    constructor: () ->

    # synchronous methods
    put: (args...) => apptools.model.put(@, args...)
    get: (args...) => apptools.model.get(@, args...)
    delete: (args...) => apptools.model.delete(@, args...)

    # asynchronous methods - tentative until params finalized
    put_async: (args...) => apptools.model.put_async(@, args...)
    get_async: (args...) => apptools.model.get_async(@, args...)
    delete_async: (args...) => apptools.model.delete_async(@, args...)

    all: (args...) => apptools.model.all(@, args...)

    render: (template) =>



@__apptools_preinit.abstract_base_classes.push CoreModelAPI
@__apptools_preinit.abstract_base_classes.push Model
