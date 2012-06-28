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
        return false for key in object
        return true

    is_array: Array.isArray or (object) =>
        return (typeof object is 'array' or Object.prototype.toString.call(object) is '[object Array]')

    in_array: (item, array) =>
        if array.indexOf?
            return !!~array.indexOf(item)

        matches = []
        for it in array
            do (it) =>
                matches.push(it) if it is item

        return matches.length > 0

    # DOM checks/manipulation
    get: (query, node=document) => # ID, class or tag
        return query if query.nodeType
        return document.getElementById(query) or node.getElementsByClassName(query) or node.getElementsByTagName(query) or false

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
        if str.charAt(0) is '#' or document.getElementById str isnt null
            return true
        else false

    # Events/timing/animation
    bind: (element, event, fn, prop=false) =>
        if @is_array element # can accept multiple els for 1 event [el1, el2]
            for el in element
                do (el) =>
                    return @bind(el, event, fn, prop)

        else if @is_raw_object event # ...or multiple events for 1 element {event: handler, event2: handler2}
            for ev, func of event
                do (ev, func) =>
                    return @bind(element, ev, func, prop)

        else
            return element.addEventListener event, fn, prop

    unbind: (element, event) =>
        if @is_array element # unbind 1 event from multiple elements
            for el in element
                do (el) =>
                    return @unbind(el, event)

        else if @is_array event # or multiple events from 1 element
            for ev in event
                do (ev) =>
                    return @unbind(element, ev)

        else if @is_raw_object(element) # or hash of elements & events
            for el, ev of element
                do (el, ev) =>
                    return @unbind(el, ev)

        else if element.constructor.name is 'NodeList'
            els = []
            els.push(item) for item in element
            return @unbind(els, event)

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
        options = if t? and @is_object t then @extend {}, t else
            complete: c or (not c and e) or (is_function t and t)
            duration: t
            easing: (c and e) or (e and not is_function e)

        return options

    throttle: (fn, buffer=150, prefire) =>

        # Throttles a rapidly-firing event (i.e. mouse or scroll)
        timer = null
        last = 0

        return () ->

            args = arguments
            elapsed = Util.now() - last

            clear = () => timer = null

            go = () =>
                last = Util.now()
                fn.apply(@, args)

            go() if prefire and not timer   # if prefire, fire @ first detect

            clearTimeout(timer) if !!timer

            if not prefire? and elapsed >= buffer
                go()
            else
                timer = setTimeout((if prefire then clear else go), (if not prefire? then buffer - elapsed else buffer))

    debounce: (fn, buffer=200, prefire=false) ->

        return @throttle(fn, buffer, prefire)

    # useful helpers
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

                for option, value of options
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
            ^#?             # may start with '#'
            [0-9A-F]{6} |   # match 6-digit hex or...
            [0-9A-F]{3}     # 3-digit short hex
            $/i             # match ending, ignoring case
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
            zfill = (s) =>
                if s.length < 2
                    s = '0'+s

            if c.length is 3 # convert to hex
                r = zfill c[0].toString 16
                g = zfill c[1].toString 16
                b = zfill c[2].toString 16

                return '#'+r+g+b

        else false

    to_rgb: (color) =>

        if color.match ///
            ^rgb\(\s*\d{1,3}\s*,\s\d{1,3}\s*, \s*\d{1,3}\s*\)$
            ///

            return color

        else if color.match ///
            ^#?([0-9A-F]{1,2})([0-9A-F]{1,2})([0-9A-F]{1,2})$/i
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

    wrap: (e, fn) =>

        # catch incoming events
        if e.preventDefault?
            e.preventDefault()
            e.stopPropagation()
        else
            fn = e

        # freshen up the context
        args = Array.prototype.slice.call arguments, 1
        return () =>
            fn.apply @, args


    constructor: () ->
        return @

    @_init = () =>
        return


@__apptools_preinit.abstract_base_classes.push Util
@__apptools_preinit.deferred_core_modules.push {module: Util}

Util = window.Util = new Util()