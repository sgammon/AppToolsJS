## AppTools drawer UI widget
class DrawerAPI extends CoreAPI

    @mount = 'drawer'
    @events = ['DRAWER_READY', 'DRAWER_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            drawers: []
            drawers_by_id: {}
            init: false

        @create = (target) =>

            options = if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            drawer = new Drawer(target, options)
            id = drawer._state.element_id

            @_state.drawers.drawers_by_id[id] = @_state.drawers.drawers.push(drawer) - 1

            return drawer._init()

        @destroy = (drawer) =>

        @enable = (drawer) =>

        @disable = (drawer) =>

        @get = (element_id) =>

        @_init = ()

class Drawer extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute 'id'
            active: false
            open: false
            init: false

            config:
                align: 'top'

                rounded: true

        @slide = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation

            el = Util.get(@_state.element_id)
            align = @_state.config.align
            final = {}


            if align is 'top' or 'bottom'

                final[align] = el.offsetHeight

            else if align is 'right' or 'left'

                final[align] = el.offsetWidth

            if @_state.open

                final[align] = -final[align]

            $(el).animate(final, Util.prep_animation())

        @_init = () =>

            @_state.init = true

            return @

