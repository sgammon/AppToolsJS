## AppTools Scroller Widget & API
class ScrollerAPI extends CoreWidgetAPI

    @mount = 'scroller'
    @events = ['SCROLLER_READY', 'SCROLLER_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            scrollers: []
            scrollers_by_id: {}
            init: false

        @internal =
            make: (scroller) =>
                scroller = @create scroller
                console.log 'CREATED SCROLLER: ', scroller
                scroller = @enable scroller
                console.log 'ENABLED SCROLLER: ', scroller

                return scroller


        @create = (target, options) =>

            options ?= if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            scroller = new Scroller target, options
            id = scroller._state.element_id
            @_state.scrollers_by_id[id] = @_state.scrollers.push(scroller) - 1

            return scroller._init()

        @destroy = (scroller) =>

            id = scroller._state.element_id

            @_state.scrollers.splice @_state.scrollers_by_id[id], 1
            delete @_state.scrollers_by_id[id]

            document.body.removeChild(Util.get(id))

            return scroller

        @enable = (scroller) =>

            for k, v of scroller._state.panes
                do (k, v) =>
                    console.log '[Scroller]', 'K: ', k
                    console.log '[Scroller]', 'V: ', v
                    Util.bind(Util.get(k), 'mousedown', scroller.jump(v))

            return scroller

        @disable = (scroller) =>

            Util.unbind(k, 'mousedown') for k in scroller._state.panes
            return scroller


        @_init = () =>

            scrollers = Util.get('pre-scroller') or []

            @create(@enable(scroller)) for scroller in scrollers

            @_state.init = true
            return @


class Scroller extends CoreWidget

    constructor: (target, options) ->

        @_state =

            frame_id: target.getAttribute 'id'
            panes: {}
            current_pane: null

            active: false
            init: false

            config:

                axis: 'horizontal'

        @_state.config = Util.extend(true, @_state.config, options)

        @classify = () =>

            target = Util.get(@_state.frame_id)
            if Util.in_array(target.classList, 'pre-scroller')
                target.classList.remove 'pre-scroller'

            panes = Util.get 'scroller-pane', target

            for pane in panes
                do (pane) =>

                    # stash trigger/target
                    trigger_id = 'a-'+pane.getAttribute 'id'
                    @_state.panes[trigger_id] = pane

                    if @_state.config.axis is 'horizontal'

                        pane.classList.remove 'left'
                        pane.classList.remove 'clear'
                        pane.classList.add 'in-table'
                        target.classList.add 'nowrap'

                    else if @_state.config.axis is 'vertical'

                        target.classList.remove 'nowrap'
                        pane.classList.remove 'in-table'
                        pane.classList.add 'left'
                        pane.classList.add 'clear'


        @jump = (pane) =>

            @_state.active = true

            animation = @animation
            animation.complete = () =>
                @_state.active = false

            @_state.current_pane = pane.getAttribute 'id'

            frameO = Util.get_offset target
            paneO = Util.get_offset pane

            if @_state.config.axis is 'horizontal'

                diff = Math.floor paneO.left - frameO.left
                $(target).animate scrollLeft: '+='+diff, animation

            else if @_state.config.axis is 'vertical'

                diff = Math.floor paneO.top - frameO.left
                $(target).animate scrollTop: '+='+diff, animation


        @_init = () =>

            @classify()

            @_state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Scroller
@__apptools_preinit.abstract_base_classes.push ScrollerAPI
@__apptools_preinit.deferred_core_modules.push {module: ScrollerAPI, package: 'widgets'}