## AppTools stickybox widget
# Scrolls up with the page until it hits the top of inner window, then sticks!
class StickyAPI extends CoreAPI

    @mount = 'sticky'
    @events = ['STICKY_READY', 'STICKY_API_READY']

    constructor: (apptools, widget, window) ->

        @create = (sticky) =>

        @destroy = (sticky) =>

        @enable = (sticky) =>

            element = Util.get(sticky._state.element_id)
            Util.bind(window, 'scroll', Util.wrap(Util.throttle(sticky.refresh), element))

            return sticky

        @disable = (sticky) =>

            Util.unbind(window, 'scroll')

            return sticky

        @_init = () =>


class Sticky extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute 'id'
            active: false
            init: false

            config:
                axis: 'vertical'
                target_offset: 0

            cache:
                original_offset: Util.get_offset(target)
                past_offset: null
                classes: target.className
                style: target.getAttribute 'style' or ''

        @_state.config = Util.extend(true, @_state.config, options)

        @refresh = (el) =>

            offset_side = if @_state.config.axis is 'vertical' then 'top' else 'left'

            current = (Util.get_offset(el))[offset_side]
            past = @_state.cache.past_offset[offset_side] or (orig = @_state.cache.original_offset[offset_side]) or false
            target = @_state.config.target_offset

            diff = if (_po = !!past) then current - past else false

            return false if (_d = +diff) is 0      # either no element or scrolled on the other axis

            if _po and _d > 0                       # scrolled up or left

                @unstick(el, offset_side) if current >= orig

            if _po and _d < 0                       # scrolled down or right

                @stick(el, offset_side) if current <= 0


        @stick = (el, side) =>

            el.classList.add 'fixed'
            el.style[side] = @_state.config.target_offset

        @unstick = (el) =>

            el.className = @_state.cache.classes
            el.style = @_state.cache.style

        @_init = () =>