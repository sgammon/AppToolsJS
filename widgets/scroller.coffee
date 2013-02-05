## AppTools Scroller Widget & API
class ScrollerAPI extends WidgetAPI

    @mount = 'scroller'
    @events = ['SCROLLER_READY', 'SCROLLER_API_READY']

    enable: (scroller) ->

        for k, v of scroller._state.panes
            do (k, v) =>
                _.get(k).addEventListener('mousedown', scroller.jump)

        return scroller

    disable: (scroller) ->

        k.removeEventListener('mousedown', scroller.jump) for k in scroller._state.panes
        return scroller

    constructor: (apptools, widget, window) ->

        super(apptools,widget, window)
        return @


class Scroller extends CoreWidget

    constructor: (target, options) ->

        @state =

            frame_id: target.getAttribute 'id'
            panes: {}
            current_pane: null

            active: false
            init: false

            config:

                axis: 'horizontal'

        @state.config = _.extend(true, @state.config, options)

        @classify = () =>

            target = _.get('#'+@state.frame_id)
            if _.in_array(target.classList, 'pre-scroller')
                target.classList.remove 'pre-scroller'

            panes = _.get '.scroller-pane', target

            for pane in panes
                do (pane) =>

                    # stash trigger/target
                    trigger_id = 'a-'+pane.getAttribute 'id'
                    @state.panes[trigger_id] = pane

                    if @state.config.axis is 'horizontal'

                        pane.classList.remove 'left'
                        pane.classList.remove 'clear'
                        pane.classList.add 'in-table'
                        target.classList.add 'nowrap'

                    else if @state.config.axis is 'vertical'

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

            frameO = _.get_offset target
            paneO = _.get_offset pane

            if @state.config.axis is 'horizontal'

                diff = Math.floor paneO.left - frameO.left
                $(target).animate scrollLeft: '+='+diff, animation

            else if @state.config.axis is 'vertical'

                diff = Math.floor paneO.top - frameO.left
                $(target).animate scrollTop: '+='+diff, animation


        @init = () =>

            @classify()

            @state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Scroller
@__apptools_preinit.abstract_base_classes.push ScrollerAPI
@__apptools_preinit.deferred_core_modules.push {module: ScrollerAPI, package: 'widgets'}