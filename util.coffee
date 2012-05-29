# Handy CS utility functions.
# You're welcome.
#
# david@momentum.io

class Util

    @mount = 'util'
    @events = []

    is: (thing) =>
        return Util.in_array thing, [false, null, NaN, undefined, 0, {}, [], '','false', 'False', 'null', 'NaN', 'undefined', '0', 'none', 'None']

    # type/membership checks
    is_function: (object) =>
        return typeof object is 'function'

    is_object: (object) =>
        return typeof object is 'object'

    is_raw_object: (object) =>
        if not object or typeof object isnt 'object' or object.nodeType or (typeof object is 'object' and 'setInterval' in object)
            return false

        if object.constructor and not object.hasOwnProperty('constructor') and not object.constructor::hasOwnProperty 'isPrototypeOf'
            return false

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

        return (matches.length > 0)

    # DOM checks/manipulation
    get: (query, node=document) => # ID, class or tag
        return document.getElementById(query) or node.getElementsByClassName(query) or node.getElementsByTagName(query) or null

    get_offset: (elem) =>
        offL = offT = 0
        loop
            offL += elem.offsetLeft
            offT += elem.offsetTop
            break unless (elem = elem.offsetParent)

        return left: offL, top: offT

    has_class: (element, cls) =>
        return if element.classList? then element.classList.contains(cls) else (element.className && new RegExp('\\s*'+cls+'\\s*').test element.className)

    is_id: (str) =>
        if str.charAt(0) is '#' or document.getElementById str isnt null
            return true
        else false

    # Events/timing/animation
    bind: (element, event, fn, prop=false) =>
        return element.addEventListener event, fn, prop

    unbind: (element, event) =>
        return element.removeEventListener event

    block: (method, object) =>
        _done = false
        result = null
        if object?
            method(object, (x) =>
                result = x
                return _done = true)

        else
            method((x) =>
                result = x
                return _done = true)

        console.log '[Util]: Enforcing blocking at user request... :('
        loop
            break unless _done is false

        return result

    now: () =>
        return new Date()

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
        options = if t and is_object t then Util.extend {}, t else
            complete: c or (not c and e) or (is_function t and t)
            duration: t
            easing: c and e or (e and not is_function e and e)

        return options

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

        # extend AppTools with single param (like jQuery, lol)
        if len is i
            target = @ # figure out what needs to go here
            i--

        # coerce type to prevent errors
        if not is_object(target) and not is_function(target)
            target = {}

        # loop fun
        args = Array.prototype.slice.call arguments, i
        for arg in args
            do (arg) =>
                options = arg

                for option, value of options
                    continue if target is value
                    o = String option
                    clone = value
                    src = target[option]

                    if deep and clone? and (is_raw_object(clone) or a = is_array(clone))

                        if a?
                            a = false
                            copied_src = src and if is_array src then src else []

                        else
                            copied_src = src and if is_raw_object src then src else {}

                        target[option] = extend(deep, copied_src, clone)

                    # else store the updated value
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