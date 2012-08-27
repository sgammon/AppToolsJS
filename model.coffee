# Model API
class ModelException extends Error

    constructor: (@source, @message) ->

    toString: () ->
        return '[' + @source + '] ModelException: ' + @message

class CoreModelAPI extends CoreAPI

    @mount = 'model'
    @events = []

    constructor: () ->

        @_state =
            init: false

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

        @_init = () ->
            @_state.init = true
            return @


class Model

    validate: (message, cls, safe=false) ->

        cls ?= this.constructor::model

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

        check(key, value) for own key, value of message

        return results if safe
        return results.length is 0

    from_message: (message={}, strict=false) ->

        object = this

        if object.validate(message)
            newobj = object.validate(message, null, true)
            object[prop] = val for prop, val of newobj

        else if not strict
            modsafe = object.validate(message, object.constructor::model, true)
            object = modsafe if not _.is_empty_object(modsafe)

        else
            console.log('from_message() failed.')

        return object

    to_message: (excludes=[]) ->

        object = this
        message = {}

        for own prop, val of object
            if typeof val isnt 'function' and object.constructor::model[prop]?
                if val.constructor.name is 'ListField'
                    _val = []
                    _val.push(item.to_message()) for item in val
                    message[prop] = _val
                else message[prop] = val

        return message

    constructor: (key) ->

        if _.is_raw_object(key) and arguments.length is 1
            @[prop] = val for prop, val of key
        else @key = key

        for m in ['to_message', 'from_message']
            do (m) =>
                @[m] = () =>
                    return Model::[m].apply(@, arguments)

        if (mounted = @constructor.mount)?
            for prop, v of @[mounted].constructor::model
                if v.constructor.name isnt 'ListField'
                    do (mounted, prop) =>
                        @__defineGetter__ prop, () =>
                            return @[mounted][prop]
                        @__defineSetter__ prop, (val) =>
                            return @[mounted][prop] = val


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
                len = @length
                front = @slice(0, index)
                back = @slice(index+1)

                newthis = @slice(0,0).push(@[index]).join(front).join(back)
            else
                item = item_or_index
                return @pick(existing) if !!~(existing = _.indexOf(@, item))

                newthis = _.to_array(@)
                newthis.unshift(item)

            @empty()
            return @join(newthis)

        @join = (separator) ->
            if separator? and (_.is_array(separator) or separator.constructor.name = @constructor.name)
                @push(item) for item in separator
                return @
            else
                string = ''
                len = @length
                for item, i in @
                    string += item.toString() if i is len-1
                    string += item.toString() + separator

                return string

        @slice = (start=0, end=@length) ->
            temp = []
            while start < end
                temp.push(@[start])
                start++

            newlist = new @constructor()
            return newlist.join(temp)

        @push = (item) ->
            len = @length
            @[len] = item
            @length++
            return @

        @empty = () ->
            @length = 0
            return @

        return @



@__apptools_preinit.abstract_base_classes.push CoreModelAPI
@__apptools_preinit.abstract_base_classes.push Model
@__apptools_preinit.abstract_base_classes.push Key
@__apptools_preinit.abstract_base_classes.push ListField
