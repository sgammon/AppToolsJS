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

    log: (source, message) ->

        if message?
            source = source.constructor.name
            if (a = $.apptools or window.apptools)?
                return a.dev.verbose(source, message)

            else
                return console.log('['+source+']', message)

        else if source?
            message = source
            source = @constructor.name

            return @log(source, message)

        else
            return @log('Model', 'No message passed to log(). (You get a log message anyway <3)')

    validate: (object, cls=object.constructor::model, safe=false) ->

        if object?

            if safe
                results = {}
                check = (k, v) =>
                    if cls[k]? and (v? is cls[k]?)
                        if cls[k].constructor.name is 'ListField'
                            temp = new ListField()
                            temp.push(new cls[k][0]().from_message(it)) for it in v
                            results[k] = temp
                        else if v.constructor.name is cls[k].constructor.name
                            results[k] = v

            else
                results = []
                check = (k, v) =>
                    if cls[k]? and (v? is cls[k]?)
                        if cls[k].constructor.name is 'ListField'
                            temp = []
                            for it in v
                                _it = new cls[k][0]().from_message(it, true)
                                temp.push(it) if it is _it
                            if temp.length > 0
                                results.push(k:v)

                        else if v.constructor.name isnt cls[k].constructor.name
                            results.push(k:v)
                    else
                        results.push(k:v)

            check(key, value) for own key, value of object

            return results if safe
            return results.length is 0

        else throw new ModelException(@constructor.name, 'No object passed to validate().')

    from_message: (object, message={}, strict=false, excludes=[]) ->

        if object?
            cached_obj = object

            if @validate(message, object.constructor::model)
                object[prop] = val for own prop, val of message if not !!~_.indexOf(excludes, prop)
                return _.exclude(object, excludes)

            else if not strict
                modsafe = @validate(message, object.constructor::model, true)
                return _.exclude((if _.is_empty_object(modsafe) then cached_obj else modsafe), excludes)

            else
                @log('from_message() failed.')
                return cached_obj

        else throw new ModelException(@constructor.name, 'No object passed to from_message().')

    to_message: (object, excludes=[]) ->

        if object?
            message = {}
            for own prop, val of object
                if object.constructor::model[prop] and typeof val isnt 'function'
                    if val.constructor.name is 'ListField'
                        _val = []
                        _val.push(item.to_message()) for item in val
                        message[prop] = _val
                    else message[prop] = val

            return message

        else throw new ModelException(@constructor.name, 'No object passed to to_message().')

    constructor: (key) ->

        if _.is_raw_object(key) and arguments.length is 1
            @[prop] = val for prop, val of key
        else @key = key

        for m in ['log', 'to_message', 'from_message']
            do (m) =>
                @[m] = (args...) =>
                    return Model::[m](@, args...)

        @template = new window.t(@constructor::template) if @constructor::template?

        return @


# represents clientside key
class Key extends Model
    model:
        key: String()

# represents repeated model property
class ListField extends Array
    constructor: () ->
        super()

        if arguments.length > 0
            _t = new ListField()
            _t.push(arguments[0])
            return _t

        @pick = (item_or_index) ->
            if parseInt(item_or_index).toString() isnt 'NaN'
                index = item_or_index
                old = [[@[index]], @slice(0, index), @slice(index+1, @length-1)]
            else
                item = item_or_index
                return @pick(existing) if !!~(existing = _.indexOf(@, item))

                old = _.to_array(@)
                old.unshift(item)

            @length = 0
            return @join(old)

        @join = (separator) =>
            if separator? and _.is_array(separator)
                joins = _.to_array(arguments)
                newthis = new ListField()
                newthis.push(item) for item in joins.shift() while joins.length
                return newthis
            else
                return @::join.call(@, separator)

        @slice = () =>
            newthis = new ListField()
            return newthis.join(@::slice.apply(@, arguments))

        return @



@__apptools_preinit.abstract_base_classes.push CoreModelAPI
@__apptools_preinit.abstract_base_classes.push Model
@__apptools_preinit.abstract_base_classes.push Key
@__apptools_preinit.abstract_base_classes.push ListField
