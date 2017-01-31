## AppTools stickybox widget
# Scrolls up with the page until it hits the top of inner window, then sticks!
class StickyAPI extends WidgetAPI

    @mount = 'sticky'
    @events = ['STICKY_READY', 'STICKY_API_READY']

    enable: (sticky) ->

        window.addEventListener('scroll', _.debounce(sticky.refresh, 15, false))
        return sticky

    disable: (sticky) ->

        window.removeEventListener('scroll')
        return sticky

    constructor: (apptools, widget, window) ->

        super(apptools, widget, window)
        return @


class Sticky extends CoreWidget

    constructor: (target, options) ->

        @state =

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

            @state.cache.original_offset = _.get('#'+@state.element_id).getOffset()

        @refresh = () =>

            el = document.getElementById(@state.element_id)
            offset_side = @state.config.side
            window_offset = if offset_side is 'top' then window.scrollY else window.scrollX
            past_offset = @state.cache.past_offset or 0

            @state.cache.past_offset = window_offset

            distance = @state.cache.original_offset[offset_side] - 5

            traveled = window_offset - distance
            scroll = window_offset - past_offset

            if scroll > 0                   # we scrolled down
                if @state.active or traveled < 0
                    return false

                else if traveled > 0
                    return @stick()

            else if scroll < 0              # scrolled up
                if not @state.active or traveled > 0
                    return false

                else if traveled < 0
                    return @unstick()

            else return false


        @stick = () =>

            @state.active = true

            el = document.getElementById(@state.element_id)

            @state.cache.classes = el.className
            @state.cache.style[prop] = val for prop, val of el.style

            el.classList.add 'fixed'
            el.style.top = -5 + 'px'
            el.style.left = @state.cache.original_offset.left + 'px'

            return @

        @unstick = () =>

            el = document.getElementById(@state.element_id)

            el.classList.remove 'fixed'
            el.style.left = ''
            el.style.top = '-170px'
            el.style.right = '5%'

            @state.active = false
            return @

        @init = () =>
            _.bind(window, 'resize', _.debounce(@recalc, 100), true)
            @state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Sticky, StickyAPI
@__apptools_preinit.deferred_core_modules.push {module: StickyAPI, package: 'widgets'}