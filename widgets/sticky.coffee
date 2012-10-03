## AppTools stickybox widget
# Scrolls up with the page until it hits the top of inner window, then sticks!
class StickyAPI extends CoreAPI

    @mount = 'sticky'
    @events = ['STICKY_READY', 'STICKY_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            stickies: []
            stickies_by_id: {}
            init: false

        @create = (target) =>

            options = _.data(target, 'options') or {}

            sticky = new Sticky(target, options)
            id = sticky._state.element_id

            @_state.stickies_by_id[id] = @_state.stickies.push(sticky) - 1

            return sticky._init()

        @destroy = (sticky) =>

        @enable = (sticky) =>

            window.addEventListener('scroll', _.debounce(sticky.refresh, 15, false))

            return sticky

        @disable = (sticky) =>

            window.removeEventListener('scroll')

            return sticky

        @get = (element_id) =>

            index = @stickies_by_id[element_id]

            return @stickies[index]

        @_init = () =>

            stickies = _.get('.pre-sticky')
            @enable(@create(sticky)) for sticky in stickies if stickies?

            apptools.events.trigger 'STICKY_API_READY', @
            @_state.init = true

            return @


class Sticky extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute 'id'
            active: false
            init: false

            config: _.extend(true,
                side: 'top'
            , options)

            cache:
                original_offset: target.getOffset()
                past_offset: null
                classes: null
                style: {}

        @recalc = () =>

            @_state.cache.original_offset = _.get('#'+@_state.element_id).getOffset()

        @refresh = () =>

            el = document.getElementById(@_state.element_id)
            offset_side = @_state.config.side
            window_offset = if offset_side is 'top' then window.scrollY else window.scrollX
            past_offset = @_state.cache.past_offset or 0

            @_state.cache.past_offset = window_offset

            distance = @_state.cache.original_offset[offset_side] - 5

            traveled = window_offset - distance
            scroll = window_offset - past_offset

            if scroll > 0                   # we scrolled down
                if @_state.active or traveled < 0
                    return false

                else if traveled > 0
                    return @stick()

            else if scroll < 0              # scrolled up
                if not @_state.active or traveled > 0
                    return false

                else if traveled < 0
                    return @unstick()

            else return false


        @stick = () =>

            @_state.active = true

            el = document.getElementById(@_state.element_id)

            @_state.cache.classes = el.className
            @_state.cache.style[prop] = val for prop, val of el.style

            el.classList.add 'fixed'
            el.style.top = -5 + 'px'
            el.style.left = @_state.cache.original_offset.left + 'px'

            return @

        @unstick = () =>

            el = document.getElementById(@_state.element_id)

            el.classList.remove 'fixed'
            el.style.left = ''
            el.style.top = '-170px'
            el.style.right = '5%'

            @_state.active = false
            return @

        @_init = () =>
            _.bind(window, 'resize', _.debounce(@recalc, 100), true)
            @_state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Sticky, StickyAPI
@__apptools_preinit.deferred_core_modules.push {module: StickyAPI, package: 'widgets'}