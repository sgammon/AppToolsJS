# Handy CS utility functions.
# You're welcome.
#
# david@momentum.io

class Util

    @mount = 'util'
    @events = []

    is: (thing) =>
        return !@in_array thing, [false, null, NaN, undefined, 0, {}, [], '','false', 'False', 'null', 'NaN', 'undefined', '0', 'none', 'None']

    # type/membership checks
    is_function: (object) =>
        return typeof object is 'function'

    is_object: (object) =>
        return typeof object is 'object'

    is_raw_object: (object) =>
        if not object or typeof object isnt 'object' or object.nodeType or (typeof object is 'object' and 'setInterval' in object)
            return false    # check if it exists, is type object, and is not DOM obj or window

        if object.constructor? and not object.hasOwnProperty('constructor') and not object.constructor::hasOwnProperty 'isPrototypeOf'
            return false    # rough check for constructed objects

        return true

    is_empty_object: (object) =>
        return false for key of object
        return true

    is_body: (object) =>
        return @is_object(object) and (Object.prototype.toString.call(object) is '[object HTMLBodyElement]' or object.constructor.name is 'HTMLBodyElement')

    is_array: Array.isArray or (object) =>
        return (typeof object is 'array' or Object.prototype.toString.call(object) is '[object Array]' or object.constructor.name is 'Array')

    in_array: (item, array) =>
        if array.indexOf?
            return !!~array.indexOf(item)

        matches = []
        for it in array
            do (it) =>
                matches.push(it) if it is item

        return matches.length > 0

    to_array: (node_or_token_list) =>
        array = []
        `for (i = node_or_token_list.length; i--; array.unshift(node_or_token_list[i]))`
        return array

    filter: (array, condition) =>       # condition function must return t/f
        new_array = []
        (if condition(item)
            new_array.push(item)
        ) for item in array
        return new_array

    sort: null

    # DOM checks/manipulation
    create_element_string: (tag, attrs, separator='*', ext) =>

        no_close = ['area', 'base', 'basefont', 'br', 'col', 'frame', 'hr', 'img', 'input', 'link']
        tag = tag.toLowerCase()

        el_str = '<' + tag
        el_str += ' ' + k + '="' + v + '"' for k, v of attrs
        el_str += ' ' + ext if ext?
        el_str += '>'
        el_str += separator + '</' + tag + '>' if not @in_array(tag, no_close)

        return el_str

    create_doc_frag: (html_string) =>
        range = document.createRange()
        range.selectNode(document.getElementsByTagName('div').item(0))
        frag = range.createContextualFragment(html_string)

        return frag

    add: (element_type, attrs, parent_node) =>
        # tag name, attr hash, doc node to insert into (defaults to body)
        if not element_type? or not @is_object(attrs)
            return false

        q_name = if (@is_body(parent_node) or not parent_node? or !(node_id = parent_node.getAttribute('id'))) then 'dom' else node_id

        @internal.queues.add(q_name) if not @_state.queues[q_name]?

        @_state.queues[q_name].push([element_type, attrs])

        @internal.queues.go(q_name, (response) =>

            q = response.queue
            parent = if response.name is 'dom' then document.body else @get(response.name)

            html = []
            html.push(@create_element_string.apply(@, args)) for args in q

            dfrag = @create_doc_frag(html.join(''))
            parent.appendChild(dfrag)
        )

    remove: (node) =>
        return node.parentNode.removeChild(node)

    get: (query, node=document) => # ID, class or tag
        return null if not query?
        return query if query.nodeType
        return if (id = document.getElementById(query))? then id else (if (cls = node.getElementsByClassName(query)).length > 0 then @to_array(cls) else (if (tg = node.getElementsByTagName(query)).length > 0 then @to_array(tg) else null))

    get_offset: (elem) =>
        offL = offT = 0
        loop
            offL += elem.offsetLeft
            offT += elem.offsetTop
            break unless (elem = elem.offsetParent)

        return left: offL, top: offT

    has_class: (element, cls) =>
        return element.classList?.contains?(cls) or element.className && new RegExp('\\s*'+cls+'\\s*').test element.className

    is_id: (str) =>
        return true if str.charAt(0) is '#'
        return true if document.getElementById(str) isnt null
        return false

    # Events/timing/animation
    bind: (element, event, fn, prop=false) =>
        return false if not element?
        if @is_array element # can accept multiple els for 1 event [el1, el2]
            @bind(el, event, fn, prop) for el in element
            return

        else if @is_array event #...multiple events for 1 handler on 1 element
            @bind(element, evt, fn, prop) for evt in event
            return

        else if @is_raw_object event # ...or multiple event/handler pairs for 1 element {event: handler, event2: handler2}
            @bind(element, ev, func, prop) for ev, func of event
            return

        else
            return element.addEventListener event, fn, prop

    unbind: (element, event) =>
        return false if not element?
        if @is_array element
            @unbind(el, event) for el in element
            return

        else if @is_array event
            @unbind(element, ev) for ev in event
            return

        else if @is_raw_object(element)
            @unbind(el, ev) for el, ev of element
            return

        else if element.constructor.name is 'NodeList' # handle nodelists from dom queries
            return @unbind(@to_array(element), event)

        else
            return element.removeEventListener event

    block: (async_method, object={}) =>
        console.log '[Util] Enforcing blocking at user request... :('

        _done = false
        result = null

        async_method object, (x) ->
            result = x
            return _done = true

        loop
            break unless _done is false
        return result

    now: () =>
        return +new Date()

    timestamp: (d) => # can take Date obj
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

    prep_animation: (t,e,c) => # time (ms), easing (jQuery easing), callback
        options = if not t? then duration: 400 else (if t? and @is_object t then @extend({}, t)else
            complete: c or (not c and e) or (is_function t and t)
            duration: t
            easing: (c and e) or (e and not is_function e)
        )

        return options

    throttle: (fn, buffer, prefire) =>
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

            if not prefire? and elapsed >= buffer
                go()
            else
                timer_id = setTimeout((if prefire then clear else go), if not prefire? then buffer - elapsed else buffer)

    debounce: (fn, buffer=200, prefire=false) ->
        return @throttle(fn, buffer, prefire)

    # useful helpers
    currency: (num) =>
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


    extend: () =>

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
            do (arg) =>
                options = arg

                for own option, value of options
                    continue if target is value # avoid crashing browsers thx
                    o = String option
                    clone = value
                    src = target[option]

                    # do we need to recurse?
                    if deep and clone? and (@is_raw_object(clone) or a = @is_array(clone))

                        if a?
                            a = false
                            copied_src = src and if @is_array src then src else []

                        else
                            copied_src = src and if @is_raw_object src then src else {}

                        target[option] = @extend(deep, copied_src, clone)

                    # nope! store the updated value
                    else if clone?
                        target[option] = clone

        return target

    to_hex: (color) =>

        if color.match ///
            ^#?                 # may start with '#'
            [0-9a-fA-F]{6} |    # match 6-digit hex or...
            [0-9a-fA-F]{3}      # 3-digit short hex
            $/i                  # match ending, ignoring case
            ///

            return if color.charAt 0 is '#' then color else '#'+color # already hex, just normalize '#'

        else if color.match ///
            ^rgb\(                      # starts with 'rgb('
            \s*                         # zero or more spaces
            (\d{1,3})                   # 1-3 digits
            \s*,\s*                     # space comma space
            (\d{1,3})\s*,\s*(\d{1,3})   # (repeat 2x more)
            \s*\)$                      # ends with ')'
            ///

            c = [ # parse as base 10
                parseInt RegExp.$1, 10
                parseInt RegExp.$2, 10
                parseInt RegExp.$3, 10
            ]

            if c.length is 3 # convert to hex
                r = @zero_fill c[0].toString 16, 2
                g = @zero_fill c[1].toString 16, 2
                b = @zero_fill c[2].toString 16, 2

                return '#'+r+g+b

        else false

    to_rgb: (color) =>

        if color.match ///
            ^rgb\(\s*\d{1,3}\s*,\s\d{1,3}\s*, \s*\d{1,3}\s*\)$
            ///

            return color

        else if color.match ///
            ^#?([0-9a-fA-F]{1,2})([0-9a-fA-F]{1,2})([0-9a-fA-F]{1,2})$/i
            ///

            c = [ # parse as hex
                parseInt RegExp.$1, 16
                parseInt RegExp.$2, 16
                parseInt RegExp.$3, 16
            ]
            r = c[0].toString 10 # convert to base 10
            g = c[1].toString 10
            b = c[2].toString 10

            return 'rgb('+r+','+g+','+b+')'

        else false

    strip_script: (link) =>

        if link.match ///^javascript:(\w\W.)/// or link.match ///(\w\W.)\(\)///

            script = RegExp.$1
            console.log 'Script stripped from link: ', script

            return 'javascript:void(0)'

        else return link

    wrap: (e, fn) ->

        i = 2

        # catch incoming events
        if e.preventDefault?
            e.preventDefault()
            e.stopPropagation()
        else
            fn = e
            i--

        # freshen up the context
        args = Array.prototype.slice.call arguments, i
        return () ->
            fn.apply @, args

    zero_fill: (num, length) =>
        return (Array(length).join('0') + num).slice(-length)

    constructor: () ->

        @_state =
            active: null

            queues:
                fx: []
                dom: []

                handlers: {}

        @internal =

            queues:

                add: (name, callback) =>

                    @_state.queues[name] = []
                    @_state.queues.handlers[name] = @debounce(
                        (n, c) => return @internal.queues.process(n, c),
                        @prep_animation().duration,
                        true)

                remove: (name, callback) =>

                    handler = @_state.queues.handlers[name]
                    delete @_state.queues.handlers[name]

                    q = @_state.queues[name]
                    delete @_state.queues[name]

                    return if q.length > 0 then {queue: q, handler: handler} else true

                go: (name, callback) =>

                    return @_state.queues.handlers[name](name, callback)

                process: (name, callback) =>

                    q = @_state.queues[name]
                    @_state.queues[name] = []

                    return callback?.call(@, {queue: q, name: name})

        @_init = (apptools) =>
            return


@__apptools_preinit.abstract_base_classes.push Util
@__apptools_preinit.deferred_core_modules.push {module: Util}

window.Util = Util = new Util()
