###
Handy utility functions.
You're welcome.

david@momentum.io
###

class Util

    @mount = 'util'
    @events = ['DOM_READY']

    constructor: () ->

        @_state =
            active: null
            init: false
            dom_status: null
            dom_ready: false

            queues:
                fx: []
                dom: []
                deferred: []
                ready: []
                default: []

            counts:
                fx: 0
                dom: 0
                deferred: 0
                ready: 0
                default: 0

            handlers:                   # batch queue handler - accepts queue as param
                default: (q) =>
                    console.log('Default queue handler called on Util, returning queue: ', q)
                    return q

                ready: (e) =>
                    # DOM ready event handler
                    if document.readyState = 'complete'
                        document.removeEventListener('DOMContentLoaded', @_state.handlers.ready, false)

                        @_state.dom_ready = true
                        @_state.dom_status = 'READY'

                        return $.apptools.events.trigger('DOM_READY')

            callbacks:                  # applied to each item in queue - accepts queued item as param
                default: null

        @internal =
            queues:
                create: (name, fn, callback_type='handler') =>

                    callback_type += 's'
                    @_state.queues[name] = []
                    @_state.counts[name] = 0
                    @_state[callback_type][name] = fn
                    return

                remove: (name, callback) =>

                    handler = @_state.handlers[name]
                    delete @_state.handlers[name]

                    q = @_state.queues[name]
                    delete @_state.queues[name]

                    response = if q.length > 0 then {queue: q, handler: handler} else true
                    return if callback? then callback(response) else response

                add: (name, item) =>
                    if not item?
                        item = name
                        name = 'default'

                    @_state.queues[name].push(item)
                    return @_state.counts[name]++

                set_handler: (name, handler) =>
                    return @_state.handlers[name] = handler

                set_callback: (name, callback) =>
                    return @_state.callbacks[name] = callback

                go: (name, q_or_item) =>
                    @_state.counts[name]--

                    if @_state.handlers[name] and @is_array(q_or_item)
                        q = q_or_item
                        return @_state.handlers[name](q)
                    else if @_state.callbacks[name]
                        item = q_or_item
                        return @_state.callbacks[name](item)
                    else return if @is_function(q_or_item) then q_or_item.call(window, window) else q_or_item

                process: (name) =>
                    q = @_state.queues[name]
                    @_state.queues[name] = []
                    results = []

                    results.push(@internal.queues.go(name, _q)) for _q in q
                    return results

        @is = (thing) =>
            return !@in_array [false, null, NaN, undefined, 0, {}, [], '','false', 'False', 'null', 'NaN', 'undefined', '0', 'none', 'None'], thing

        # type/membership checks
        @is_function = (object) =>
            return typeof object is 'function'

        @is_object = (object) =>
            return typeof object is 'object'

        @is_raw_object = (object) =>
            if not object or typeof object isnt 'object' or object.nodeType or @is_window(object)
                return false    # check if it exists, is type object, and is not DOM obj or window

            if object.constructor? and not object.hasOwnProperty('constructor') and not object.constructor::hasOwnProperty 'isPrototypeOf'
                return false    # rough check for constructed objects

            return true

        @is_empty_object = (object) =>
            return false for key of object
            return true

        @is_window = (object) =>
            return typeof object is 'object' and (!!~@indexOf(object.constructor::, 'setInterval') or (object.self? and object.self is object) or (Window? and object instanceof Window))

        @is_body = (object) =>
            return @is_object(object) and (Object.prototype.toString.call(object) is '[object HTMLBodyElement]' or object.constructor.name is 'HTMLBodyElement')

        @is_array = Array.isArray or (object) =>
            return (typeof object is 'array' or Object.prototype.toString.call(object) is '[object Array]' or object.constructor.name is 'Array')

        @is_string = (str) =>
            return str.constructor.name is 'String' or (str.charAt and str.length)

        @in_array = (array, item) =>
            return !!~@indexOf(array, item)

        @to_array = (node_or_token_list) =>
            array = []
            `for (i = node_or_token_list.length; i--; array.unshift(node_or_token_list[i]))`
            return array

        @indexOf = (arr, item) =>
            if @is_array(arr)
                if (_i = Array.prototype.indexOf)?
                    return _i.call(arr, item)
                else
                    i = arr.length
                    while i--
                        return i if arr[i] is item
                    return -1

            else if @is_object(arr)
                result = -1
                for own key, val of arr
                    continue if val isnt item
                    result = key
                    break
                return result

            else throw 'indexOf() requires an iterable as the first parameter'


        @each = (arr, fn, ctx=window) =>
            if typeof fn isnt 'function'
                throw 'each() requires an iterator as the second parameter'
            else
                results = []
                if @is_array(arr)
                    return _e.call(arr, fn, ctx) if (_e = Array.prototype.forEach)?
                    results.push(fn.call(ctx, item, i, arr)) for item, i in arr
                else if @is_object(arr)
                    results.push(fn.call(ctx, val, k, arr)) for k, val of arr
                else throw 'each() requires an iterable as the first parameter'

                return

        @map = (arr, fn, ctx=window) =>
            if typeof fn isnt 'function'
                throw 'map() requires an iterator as the second parameter'
            else
                if @is_array(arr)
                    return _m.call(arr, fn, ctx) if (_m = Array.prototype.map)?
                    results = []
                    (results.push(fn.call(ctx, item, i, arr))) for item, i in arr
                else if @is_object(arr)
                    results = {}
                    (results[k] = fn.call(ctx, val, k, arr)) for own k, val of arr
                else throw 'map() requires an iterable as the first parameter'

                return results

        @filter = (arr, fn, ctx=window) =>
            if typeof fn isnt 'function'
                throw 'filter() requires an iterator as the second parameter'
            else
                if @is_array(arr)
                    return _f.call(arr, fn, ctx) if (_f = Array.prototype.filter)?
                    results = []
                    (results.push(item) if fn.call(ctx, item, i, arr)) for item, i in arr
                else if @is_object(arr)
                    results = {}
                    (results[k] = val if fn.call(ctx, val, k, arr)) for own k, val of arr
                else throw 'filter() requires an iterable as the first parameter'

                return results

        @reject = (arr, fn, ctx=window) =>
            if typeof fn isnt 'function'
                throw 'reject() requires an iterator as the second parameter'
            else
                if @is_array(arr)
                    results = []
                    (results.push(item) if not fn.call(ctx, item, i, arr)) for item, i in arr
                else if @is_object(arr)
                    results = {}
                    (results[k] = val if not fn.call(ctx, val, k, arr)) for own k, val of arr
                else throw 'reject() requires an iterable as the first parameter'

                return results

        @exclude = (array, excludes) =>
            if @is_array(array)
                results = []
                (results.push(item) if not !!~@indexOf(excludes, item)) for item in array
            else if @is_object(array)
                results = {}
                (results[k] = v if not !!~@indexOf(excludes, k)) for k, v of array
            else throw 'exclude() requires two iterables'

            return results

        @all = (arr, fn, ctx=window) =>
            if typeof fn isnt 'function'
                throw 'all() requires an iterator as the second parameter'
            else
                if (_arr = @is_array(arr)) or (_obj = @is_object(arr))
                    (return _all.call(arr, fn, ctx) if (_all = Array.prototype.every)?) if _arr
                    results = @reject(arr, fn, ctx)
                    return if _arr then results.length is 0 else false for key of _obj
                else throw 'all() requires an iterable as the first parameter'

        @any = (arr, fn, ctx=window) =>
            if typeof fn isnt 'function'
                throw 'any() requires an iterator as the second parameter'
            else
                if (_arr = @is_array(arr)) or (_obj = @is_object(arr))
                    (return _any.call(arr, fn, ctx) if (_any = Array.prototype.some)?) if _arr
                    results = @filter(arr, fn, ctx)
                    return if _arr then results.length > 0 else true for key of _obj
                else throw 'any() requires an iterable as the first parameter'


        @reduce = (arr, fn, initial, ctx=window) =>
            initial ?= if @is_array(arr[0]) then [] else 0
            if typeof fn isnt 'function'
                throw 'reduce() requires an iterator as the second parameter'
            else
                if @is_array(arr)
                    return _r.call(arr, fn, initial, ctx) if (_r = Array.prototype.reduce)?
                    results = initial
                    fn.call(ctx, results, item, arr) for item in arr
                    return results
                else throw 'reduce() requires an array as the first parameter'

        @reduce_right = (arr, fn, initial, ctx=window) =>
            initial ?= if @is_array(arr[last = arr.length - 1]) then [] else 0
            if typeof fn isnt 'function'
                throw 'reduce_right() requires an iterator as the second parameter'
            else
                if @is_array(arr)
                    return @reduce(arr.reverse(), fn, initial, ctx)
                else throw 'reduce_right() requires an array as the first parameter'

        @sort = (arr, fn) =>
            if fn? and typeof fn isnt 'function'
                throw 'sort() requires an iterator as the second parameter'
            else if (_s = Array.prototype.sort)?
                return _s.call(arr, fn)
            else
                console.log('non-native sort() currently stubbed.')
                return false

        @defaults = (obj, def_obj={}) =>
            new_obj = obj
            if @is_array(obj)
                for o, i in obj
                    if not o?
                        new_obj[i] = def_obj[i]

            else if @is_object(obj)
                for k, v of obj
                    if not v?
                        new_obj[k] = def_obj[k]

            else throw 'Defaults requires an iterable as the first param.'
            return new_obj

        @first = (array) =>
            arr = array
            return arr.shift()

        @last = (array) =>
            arr = array
            return arr.pop()

        @purge = (array) =>
            return @filter(array, (it) => return @is(it))

        @empties = (array) =>
            idxs = []
            _.each array, (it, i) =>
                idxs.push(i) if not @is(it)
                return
            return idxs

        # DOM checks/manipulation
        @create_element_string = (tag, attrs, separator='*', ext) =>
            no_close = ['area', 'base', 'basefont', 'br', 'col', 'frame', 'hr', 'img', 'input', 'link']
            tag = tag.toLowerCase()

            el_str = '<' + tag
            el_str += ' ' + k + '="' + v + '"' for k, v of attrs
            el_str += ' ' + ext if ext?
            el_str += '>'
            el_str += separator + '</' + tag + '>' if not @in_array(no_close, tag)

            return el_str

        @create_doc_frag = () =>
            html_string = ''
            html_string += arg for arg in arguments
            range = document.createRange()
            range.selectNode(document.getElementsByTagName('div').item(0))
            frag = range.createContextualFragment(html_string)

            return frag

        @to_doc_frag = (node) =>

            frag = document.createDocumentFragment()
            frag.appendChild(node)

            return frag


        @add = (element_type, attrs, parent_node=document.body) =>
            # tag name, attr hash, doc node to insert into (defaults to body)
            if not element_type? or not @is_object(attrs)
                return false

            handler = @debounce((response) =>
                q = response
                parent = parent_node

                html = []
                html.push(@create_element_string.apply(@, args)) for args in q

                dfrag = @create_doc_frag(html.join(''))
                parent.appendChild(dfrag)
            , 500, false)

            q_name = if (@is_body(parent_node) or not parent_node? or !(node_id = parent_node.getAttribute('id'))) then 'dom' else node_id

            if not @_state.queues[q_name]?
                @internal.queues.create(q_name, handler: handler)

            else if not @_state.handlers[q_name]?
                @internal.queues.add_handler(q_name, handler)

            @internal.queues.add(q_name, [element_type, attrs])
            @internal.queues.process(q_name)


        @remove = (node) =>
            return node.parentNode.removeChild(node)

        @get = (query, node=document) => # ID, class or tag
            if @is_window node
                node = document
            return query if not query? or query.nodeType
            if @in_array(['.', '#'], query[0])
                [selector, query] = [query[0], query.slice(1)]
                return (if selector is '#' then document.getElementById(query) else @to_array(node.getElementsByClassName(query)))
            else
                return id if (id = document.getElementById(query))?
                return (if cls.length > 1 then @to_array(cls) else cls[0]) if (cls = node.getElementsByClassName(query)).length > 0
                return (if tg.length > 1 then @to_array(tg) else tg[0]) if (tg = node.getElementsByTagName(query)).length > 0
                return null

        @get_offset = (elem) =>
            offL = offT = 0
            loop
                offL += elem.offsetLeft
                offT += elem.offsetTop
                break unless (elem = elem.offsetParent)

            return left: offL, top: offT

        @has_class = (element, cls) =>
            return element.classList?.contains?(cls) or element.className && new RegExp('\\s*'+cls+'\\s*').test element.className

        @is_id = (str) =>
            return true if str.charAt(0) is '#'
            return true if document.getElementById(str) isnt null
            return false

        @is_child = (parent, child) =>
            result = false
            if @is_array(child)
                results = _.reject(_.map(child, (ch)=> return @is_child(parent, ch)), (r) => return r)
                result = results.length is 0
            else
                while child = child.parentNode
                    continue if child isnt parent
                    result = true
                    break

            return result

        @resolve_common_ancestor = (elem1, elem2, bound_elem=document.body) =>
            if not @is_child(bound_elem, [elem1, elem2])
                throw 'Bounding node must contain both search elements'
            else
                searched_elems = []
                match = null
                go1 = true
                go2 = true
                while go1 or go2
                    if go1
                        if @in_array(searched_elems, elem1)
                            match = elem1
                            break
                        else
                            searched_elems.push(elem1)
                            go1 = (elem1 isnt bound_elem) and (elem1 = elem1.parentNode) and elem1?
                    if go2
                        if @in_array(searched_elems, elem2)
                            match = elem2
                            break
                        else
                            searched_elems.push(elem2)
                            go2 = (elem2 isnt bound_elem) and (elem2 = elem2.parentNode) and elem2?
                    continue

                return match

        # Events/timing/animation
        @bind = (element, event, fn, prop=false) =>
            return false if not element? or not event?

            if @is_window(element) or element.nodeType or ((a = @is_array(element)) and element.length > 0 and element[0].nodeType)
                # DOM event binding
                if @is_raw_object(event)
                    element.addEventListener(k, v, prop) for k, v of event
                    return
                if a
                    event = [event] if not @is_array(event)
                    el.addEventListener(ev, fn, prop) for el in element for ev in event
                    return
                else
                    return element.addEventListener(event, fn, prop)
            else
                # AppTools bind, reassign vars
                [event, fn, prop] = [element, event, fn]
                return (if @is_function(fn) then $.apptools.events.hook(event, fn, prop) else $.apptools.events.bridge(event, fn, prop))

        @bridge = () =>
            return @bind.apply(@, arguments)

        @trigger = () =>
            return $.apptools.events.trigger.apply($.apptools.events, arguments)

        @unbind = (element, event) =>
            return false if not element?
            if @is_array element
                @unbind(el, event) for el in element
                return

            else if @is_array event
                @unbind(element, ev) for ev in event
                return

            else if @is_raw_object(element)
                @unbind(_el, evt) for _el, evt of element
                return

            else if element.constructor.name is 'NodeList' # handle nodelists from dom queries
                return @unbind(@to_array(element), event)

            else
                return element.removeEventListener event

        @block = (async_method, object={}) =>
            console.log '[Util]', 'Enforcing blocking at user request... :('

            _done = false
            result = null

            async_method object, (x) ->
                result = x
                return _done = true

            loop
                break unless _done is false
            return result

        @defer = (fn, timeout=false) =>

            if typeof fn is 'boolean'
                return @ready(fn)

            else if not @is(t = parseInt(timeout))
                return false

            else return setTimeout(fn, t)

        @ready = (fn) =>

            if not @_state.dom_status?
                @_state.dom_status = 'NOT_READY'
                @bind('DOM_READY', @ready)
                document.addEventListener('DOMContentLoaded', @_state.handlers.ready, false)

            if not fn? and @_state.dom_ready
                return @internal.queues.process('ready')

            else if @is_function(fn)
                @internal.queues.add('ready', fn)

                if document.readyState is 'complete' and @_state.dom_ready is true
                    return @defer(@ready, 1)

                else return

        @now = () =>
            return +new Date()

        @timestamp = (d) => # can take Date obj
            d ?= new Date()
            return [
                [
                    d.getMonth() + 1
                    d.getDate()
                    d.getFullYear()
                ].join('-'),
                [
                    d.getHours()
                    d.getMinutes()
                    d.getSeconds()
                ].join(':'),
            ].join ' '

        @prep_animation = (t,e,c) => # time (ms), easing (jQuery easing), callback
            options = if not t? then duration: 400 else if t? and @is_object t then @extend({}, t) else
                complete: c or (not c and e) or (_this.is_function(t) and t)
                duration: t
                easing: (c and e) or (e and not is_function e)

            return options

        @throttle = (fn, buffer, prefire=false) =>
            # Throttles a rapidly-firing event (i.e. mouse or scroll)
            timer_id = null
            last = 0

            return () =>

                args = arguments
                elapsed = @now() - last

                clear = () =>
                    go()
                    timer_id = null

                go = () =>
                    last = @now()
                    fn.apply(@, args)

                go() if prefire and not timer_id   # if prefire, fire @ first detect

                clearTimeout(timer_id) if !!timer_id

                if not prefire and elapsed >= buffer
                    go()
                else
                    timer_id = setTimeout((if prefire then clear else go), if not prefire then buffer - elapsed else buffer)

        @debounce = (fn, buffer=200, prefire=false) ->
            return @throttle(fn, buffer, prefire)

        # useful helpers
        @currency = (num) =>
            len = (nums = String(num).split('').reverse()).length

            new_nums = []

            process = (c, i) =>
                if (i+1) % 3 is 0 and len - i > 1
                    sym = ','
                else if i is len - 1
                    sym = '$'
                else
                    sym = ''
                new_nums.unshift(sym + c)

            process(char, index) for char, index in nums
            return new_nums.join('')

        @extend = () =>

            target = arguments[0] or {}
            i = 1
            deep = false
            len = arguments.length

            # check if deep copy
            if typeof target is 'boolean'
                deep = target
                target = arguments[1] or {}
                i++

            # coerce type to prevent errors
            if not @is_object(target) and not @is_function(target)
                target = {}

            # loop fun
            args = Array.prototype.slice.call arguments, i
            for arg in args
                object = arg

                for own key, value of object
                    continue if target is value # avoid crashing browsers thx
                    o = String key
                    clone = value
                    src = target[key]

                    # do we need to recurse?
                    if deep and clone? and (@is_raw_object(clone) or a = @is_array(clone))

                        if a
                            a = false
                            copied_src = src and if @is_array src then src else []

                        else
                            copied_src = src and if @is_raw_object src then src else {}

                        target[key] = @extend(deep, copied_src, clone)

                    # nope! store the updated value
                    else if clone?
                        target[key] = clone

            return target

        @to_hex = (color) =>

            if color.match ///
                ^\#?                # may start with '#'
                [0-9a-fA-F]{6} |    # match 6-digit hex or...
                [0-9a-fA-F]{3}      # 3-digit short hex
                $///i               # match ending, ignoring case

                return if color.charAt 0 is '#' then color else '#'+color   # already hex, just normalize '#'

            else if color.match ///
                ^rgb\(                      # starts with 'rgb('
                \s*                         # zero or more spaces
                (\d{1,3})                   # 1-3 digits
                \s*,\s*                     # ?space? comma ?space?
                (\d{1,3})\s*,\s*(\d{1,3})   # (repeat 2x more)
                \s*\)$///i                  # ends with ')'

                # parse into base 10
                c = [
                    parseInt RegExp.$1, 10
                    parseInt RegExp.$2, 10
                    parseInt RegExp.$3, 10
                ]
                # convert to hex string
                if c.length is 3
                    r = @zero_fill c[0].toString 16, 2
                    g = @zero_fill c[1].toString 16, 2
                    b = @zero_fill c[2].toString 16, 2

                    return '#'+r+g+b

            else false

        @to_rgb = (color) =>
            if color.match ///^rgb\s*\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*\)\s*$///
                return color

            else if color.match ///^\#?([0-9a-fA-F]{1,2})([0-9a-fA-F]{1,2})([0-9a-fA-F]{1,2})$///i
                # parse into hex
                c = [
                    parseInt RegExp.$1, 16
                    parseInt RegExp.$2, 16
                    parseInt RegExp.$3, 16
                ]
                #c onvert to base 10 string
                r = c[0].toString 10
                g = c[1].toString 10
                b = c[2].toString 10

                return 'rgb('+r+','+g+','+b+')'

            else false

        @strip_script = (link) =>

            if link.match ///^javascript:(\w\W.)/// or link.match ///(\w\W.)\((.*)\)///

                script = RegExp.$1
                console.log 'Script stripped from link: ', script

                return 'javascript:void(0)'

            else return link

        @wrap = (e, fn) ->

            i = 2

            # catch incoming events
            if e.preventDefault?
                e.preventDefault()
                e.stopPropagation()
            else
                fn = e
                i--

            # freshen up the context
            args = Array.prototype.slice.call(arguments, i)
            return () ->
                fn.apply @, args

        @zero_fill = (num, length) =>
            return (Array(length).join('0') + num).slice(-length)

        @_init = () =>
            @_state.init = true
            return @


@__apptools_preinit.abstract_base_classes.push Util
@__apptools_preinit.deferred_core_modules.push {module: Util}

window.Util = Util

if window._?
    window._cached = window._
    window._ = null

window._ = new Util()

if window.$?
    $.extend _: window._
else
    window.$ = window._.get
