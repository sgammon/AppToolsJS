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

    validate: (message, cls=@constructor::model, strict=true) ->

        if strict
            results = []
            check = (k, v) =>
                if (_v = cls[k])? and (v? is _v?)
                    if typeof _v is 'function'
                        t = new _v()
                        results.push(k:v) if not t.validate(v)

                    else if _v.constructor.name is 'ListField'
                        _it = new _v[0]()
                        for it in v
                            continue if _it.validate(it)
                            results.push(k:v)
                            break

                    else if v.constructor.name isnt _v.constructor.name
                        results.push(k:v)
                else results.push(k:v)

        else
            results = {}
            check = (k, v) =>
                if (_v = cls[k])? and (v? is _v?)
                    if typeof _v is 'function'
                        results[k] = new _v().from_message(v)

                    else if _v.constructor.name is 'ListField'
                        temp = new ListField()
                        temp.push(new _v[0]().from_message(it)) for it in v
                        results[k] = temp

                    else if v.constructor.name is _v.constructor.name
                        results[k] = v

        check(key, value) for own key, value of message

        return results if strict
        return results.length is 0

    from_message: (message={}, strict=false) ->

        object = @
        valid = object.validate(message)
        modsafe = object.validate(message, null, false)

        if strict and not valid
            console.log('Strict from_message() failed. Returning unmodified object.', object)
        else if _.is_empty_object(modsafe)
            console.log('No modelsafe properties found. Returning unmodified object.', object)
        else
            object[prop] = val for prop, val of modsafe

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

        for m in Model::
            do (m) =>
                @::[m] = () =>
                    return Model::[m].apply(@, arguments)

        if @constructor.mount?
            mounted = @[@constructor.mount]
            if mounted?
                for prop, v of mounted.constructor::model
                    if v.constructor.name isnt 'ListField'
                        do (mounted, prop) =>
                            @__defineGetter__ prop, () =>
                                return mounted[prop]
                            @__defineSetter__ prop, () =>
                                return

        @template = new window.t(temp) if (temp = @constructor::template or @constructor.template)?

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

        @pick = (item_or_index, new_index) ->
            if parseInt(item_or_index).toString() isnt 'NaN'
                index = item_or_index
                len = @length

                if new_index?
                    diff = index - new_index

                    if diff > 0
                        new_front = @slice(0, new_index)
                        newthis = new_front.join(@slice(new_index).pick(diff))

                    else
                        _d = -diff
                        new_front = @slice(0, index )
                        new_back = @slice(index)
                        while diff < 0
                            new_back.pick(_d)
                            diff++
                        newthis = new_front.join(new_back)

                else
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

        @keys = () ->
            ks = []
            ks.push(item.key) for item in @

            return _.purge(ks)

        @order = (new_index, prop=false) ->           # prop - optional, property on each object in this ListField to sort by

            oldthis = new ListField().join(@)
            @empty()
            @length = new_index.length

            _.map(oldthis, (item, i, arr) ->
                @[_.indexOf(new_index)] = (if !!prop then item[prop] else item)
            , @)

            return @

        @promote = (key_or_index) =>
            if parseInt(key_or_index).toString() isnt 'NaN'
                index = key_or_index
            else
                key = key_or_index
                index = _.indexOf(@keys(), key)

            return @pick(index, index-1)

        @demote = (key_or_index) =>
            if parseInt(key_or_index).toString() isnt 'NaN'
                index = key_or_index
            else
                key = key_or_index
                index = _.indexOf(@keys(), key)

            return @pick(index, index+1)

        @remove = (key_or_index) =>
            if parseInt(key_or_index).toString() isnt 'NaN'
                index = key_or_index
            else
                key = key_or_index
                index = _.indexOf(@keys(), key)

            copy = @slice()
            newthis = copy.slice(0, index).join(copy.slice(index+1))

            @empty()

            return @join(newthis)

        return @



@__apptools_preinit.abstract_base_classes.push CoreModelAPI, Model, Key, ListField