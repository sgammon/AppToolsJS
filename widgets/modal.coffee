## AppTools Modal Widget & API
class ModalAPI extends WidgetAPI

    @mount: 'modal'
    @events: ['MODAL_READY', 'MODAL_API_READY']

    get_active: () ->

        modals = @state.data
        active = false

        for modal in modals
            continue if not modal.state.active
            active = modal
            break

        return active

    constructor: (apptools, widget, window) ->

        super(apptools, window)

        @enable = (widget) ->

            widget_el = _.get('#' + widget.id)
            trigger = _.get('#' + widget_el.data('trigger'))
            if not trigger.data('uuid')?
                trigger.data('uuid', widget.uuid)

            event = widget.constructor::event

            trigger.addEventListener(event, widget.handler, false)

            return widget

        return @


class Modal extends CoreWidget

    template: 'ModalWidget'
    event: 'click'

    handler: (e) ->

        return false if not e.target

        if e.preventDefault
            e.preventDefault()
            e.stopPropagation()

        uuid = e.target.data('uuid')

        modal = $.apptools.widgets.get(uuid)
        active = modal.state.active

        e.target.removeEventListener('click', modal.handler, false)

        final = modal.css()

        if active

            trigger = modal.state.trigger
            target = _.get('#'+modal.id).find('modal-fade')
            callback = (t) ->
                m = t.parentNode
                m.animate final,
                    callback: (m) ->
                        m.style.display = 'none'
                        modal.state.active = false
                        trigger.addEventListener('click', modal.handler, false)

            target.fadeOut(callback: callback)

        else

            target = _.get('#' + modal.id)
            trigger = target.find('modal-close')
            callback = (t) ->
                t.find('modal-fade').fadeIn()
                t.find('modal-close').addEventListener('click', modal.handler, false)

            modal.state.active = true
            target.style.display = 'block'
            target.animate final,
                callback: callback

        return modal

    css: () ->

        if @state.config.css?
            return @state.config.css()

        wW = window.innerWidth
        wH = window.innerHeight
        r = @state.config.ratio

        if @state.active and arguments.length is 0

            css = _.extend({}, css, @state.config.initial)
            css.opacity = 0

        else

            fixed = !!@state.config.size
            dW = (if fixed then @state.config.size.width + 10 else Math.floor r.x*wW + 20)
            dH = (if fixed then @state.config.size.height + 10 else Math.floor r.y*wH + 20)
            css =
                width: dW
                height: dH
                left: Math.floor((wW-dW)/2)
                top: Math.floor((wH-dH)/2)
                opacity: 1

        return css

    resize: (e) ->

        if e.preventDefault
            e.preventDefault()
            e.stopPropagation()

        modal = $.apptools.widgets.modal.get_active()

        css = modal.css('resize')

        modal_el = _.get('#' + modal.id)
        modal_el.style[prop] = val + 'px' for prop, val of css

        return modal

    constructor: (target, options) ->

        target_id = target.getAttribute('id')
        super(target_id)

        @state =

            overlay: null
            title: target.data('title')

            active: false
            init: false

            config: _.extend(true,

                initial:                                # style props at animate start
                    width: '0'
                    height: '0'
                    top: window.innerHeight/2
                    left: window.innerHeight/2

                ratio:                                  # 0-1, final size vs. window inner
                    x: 0.4
                    y: 0.4

                size: null                              # for fixed width/height: integers or percentages

                rounded: true

            , options)

            cached:
                id: target_id
                el: null

            history: []
            element: target
            trigger: _.get(target.data('trigger'))

        @init = (trigger) =>

            source = _.get('#' + @state.cached.id)
            @state.cached.el = source

            @render

                id: @id
                uuid: @uuid
                rounded: @state.config.rounded
                title: @state.title
                content: source.innerHTML
                trigger: @state.trigger.getAttribute('id')

            if not !!@state.config.size
                window.addEventListener('resize', _.throttle(@resize, 350, false), true)

            @state.init = true

            delete @init
            return @



@__apptools_preinit.abstract_base_classes.push Modal
@__apptools_preinit.abstract_base_classes.push ModalAPI
@__apptools_preinit.deferred_core_modules.push {module: ModalAPI, package: 'widgets'}