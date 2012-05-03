## AppTools Widget Core
class CoreWidgetAPI extends CoreAPI

    @mount = 'widget'
    @events = []

    constructor: (apptools, window) ->

        return

    prime: (elements, action, event='mousedown') ->

        return trigger.addEventListener event, action target, false for trigger, target of elements

    unprime: (elements, event='mousedown') ->

        return trigger.removeEventListener event for trigger in elements

    _init: (apptools) ->
        apptools.sys.state.add_flag 'widgets'
        apptools.dev.verbose 'CoreWidget', 'Widget functionality is currently stubbed.'
        return


class CoreWidget extends CoreObject

    @util =

        bind: (element, event, fn, prop=false) ->

            return element.addEventListener event, fn, prop

        unbind: (element, event) ->

            return element.removeEventListener event

        get: (query, node=document) ->

            # return DOM element(s) by ID, class or tag
            return node.getElementById(query) or
                node.getElementsByClassName(query) or
                node.getElementsByTagName(query) or false

        getOffset: (elem) ->

            offL = offT = 0

            loop
                offL += elem.offsetLeft
                offT += elem.offsetTop
                break unless (node = node.offsetParent)

            return left: offL, top: offT

        hasClass: (element, cls) ->

            # regex!
            return elem.className && new RegExp('\\s*'+cls+'\\s*').test elem.className

        is: (thing) ->

            # test for falsity or emptiness
            if [false, null, NaN, undefined, 0, {}, [], '','false', 'False', 'null', 'NaN', 'undefined', '0', 'none', 'None'].indexOf(thing) is -1
                return true
            else false

        isID: (str) ->

            if str.charAt(0) is '#' or document.getElementById str isnt null
                return true
            else false

        stripScript: (link) ->

            if link.match ///
                ^javascript: # assume any link starting with "javascript:" is up to no good...
                (\w\W.) # capture everything following to log
                ///

                script = RegExp.$1
                apptools.dev.verbose 'SCRIPT_WARNING', 'User attempted to add script to page: ', script

                return 'javascript:void(0)'

            else link

        toHex: (color) ->

            if color.match ///
                ^#?             # may start with '#'
                [0-9A-F]{6} |   # match 6-digit hex or...
                [0-9A-F]{3}     # 3-digit short hex
                $/i             # match ending, ignoring case
                ///

                return if color.charAt 0 is '#' then color else '#'+color

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
                zfill = (s) ->
                    if s.length < 2
                        s = '0'+s

                if c.length is 3 # convert to hex
                    r = zfill c[0].toString 16
                    g = zfill c[1].toString 16
                    b = zfill c[2].toString 16

                    return '#'+r+g+b

            else false

        toRGB: (color) ->

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

        wrap: (e, fn) ->

            # catch incoming events
            if e.preventDefault?
                e.preventDefault()
                e.stopPropagation()
            else
                fn = e

            # freshen up the context a bit
            args = Array.prototype.slice.call arguments, 1
            return () ->
                fn.apply @, args

    @animation =
        duration: 400
        easing: 'easeInOutExpo'
        complete: null

    @overlay = (prefix='momentum') ->

        overlay = document.createElement 'div'
        overlay.className = 'fixed overlay'
        overlay.setAttribute 'id', prefix+'-overlay'
        overlay.style.opacity = 0

        return overlay


if @__apptools_preinit?
    if not @__apptools_preinit.abstract_base_classes?
        @__apptools_preinit.abstract_base_classes = []
    if not @__apptools_preinit.deferred_core_modules?
        @__apptools_preinit.deferred_core_modules = []
else
    @__apptools_preinit =
        abstract_base_classes: []
        deferred_core_modules: []

@__apptools_preinit.abstract_base_classes.push CoreWidget
@__apptools_preinit.abstract_base_classes.push CoreWidgetAPI
@__apptools_preinit.deferred_core_modules.push {module: CoreWidgetAPI}
