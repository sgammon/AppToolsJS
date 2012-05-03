class Scroller extends CoreWidget

    constructor: (target, options) ->

        @state =
            el: target
            panes: {}
            current_pane: null
            active: false
            init: false

        @defaults =
            axis: 'horizontal'

        @config = $.extend true, @defaults, options

        @classify = () =>

            panes = @util.get 'scrollerpane', target

            for pane in panes
                do (pane) =>

                    # stash trigger/target
                    @state.panes[@util.get 'a-'+pane.getAttribute 'id'] = pane

                    if @config.axis is 'horizontal'

                        pane.classList.remove 'left'
                        pane.classList.remove 'clear'
                        pane.classList.add 'in-table'
                        target.classList.add 'nowrap'

                    else if @config.axis is 'vertical'

                        target.classList.remove 'nowrap'
                        pane.classList.remove 'in-table'
                        pane.classList.add 'left'
                        pane.classList.add 'clear'


        @jump = (pane) =>

            @state.active = true

            animation = @animation
            animation.complete = () =>
                @state.active = false
                @state.current_pane = pane.getAttribute 'id'

            frameO = @util.getOffset target
            paneO = @util.getOffset pane

            if @config.axis is 'horizontal'

                diff = Math.floor paneO.left - frameO.left
                $(target).animate scrollLeft: '+='+diff, animation

            else if @config.axis is 'vertical'

                diff = Math.floor paneO.top - frameO.left
                $(target).animate scrollTop: '+='+diff, animation


    _init: () =>

        @classify()

        @state.init = true
        return $.apptools.events.trigger 'SCROLLER_READY', @


class ScrollerAPI extends CoreWidgetAPI

    @mount = 'scroller'
    @events = ['SCROLLER_READY', 'SCROLLER_API_READY']

    constructor: (apptools, widget, window) ->

        @state =
            scrollers: []
            scrollers_by_id: {}
            next: scrollers.length

        @create = (target, options={}) =>

            scroller = new Scroller target, options
            @state.scrollers_by_id[scroller.state.el.getAttribute 'id'] = @state.next
            @state.scrollers.push scroller

            return scroller

        @destroy = (scroller) =>

            id = scroller.state.el.getAttribute 'id'

            @state.scrollers.splice @state.scrollers_by_id[id], 1
            delete @state.scrollers_by_id[id]

            return scroller

        @enable = (scroller) =>

            @prime scroller.state.panes, scroller.jump
            return scroller

        @disable = (scroller) =>

            @unprime scroller.state.panes
            return scroller


    _init: (apptools) =>

        scrollers = @util.get 'scroller'
        for scroller in scrollers
            do (scroller) =>
                axis = scroller.getAttribute 'data-axis'
                scroller = if axis? then @create scroller, axis: axis else @create scroller
                scroller = @enable scroller

        return apptools.events.trigger 'SCROLLER_API_READY', @


@__apptools_preinit.abstract_base_classes.push ColorPicker
@__apptools_preinit.abstract_base_classes.push ColorPickerAPI
@__apptools_preinit.deferred_core_modules.push {module: ColorPickerAPI, package: 'widgets'}