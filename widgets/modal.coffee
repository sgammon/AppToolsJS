## AppTools Modal Widget & API
class ModalAPI extends CoreWidgetAPI

    @mount = 'modal'
    @events = ['MODAL_READY', 'MODAL_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            modals: []
            modals_by_id: {}
            init: false

        @create = (target, trigger, callback, options) =>

            options ?= _.data(target, 'options') or {}

            modal = new Modal(target, trigger, options)
            id = modal._state.cached_id

            @_state.modals_by_id[id] = @_state.modals.push(modal) - 1
            modal._init()

            return if callback? then callback(modal) else modal

        @destroy = (modal) =>

            modal = @disable(modal)

            id = modal._state.element_id
            el = _.get(id)
            cached_id = modal._state.cached_id
            cached_el = _.get(cached_id)

            @_state.modals.splice(@_state.modals_by_id[id], 1)
            delete @_state.modals_by_id[id]

            el.parentNode.removeChild(el)
            cached_el.parentNode.removeChild(cached_el)

            return modal

        @enable = (modal) =>

            trigger = _.get(modal._state.trigger_id)
            trigger.addEventListener('mousedown', modal.open, false)

            return modal

        @disable = (modal) =>

            _.get(modal._state.trigger_id).removeEventListener('mousedown', modal.open)

            return modal

        @get = (element_id) =>

            return if (index = @_state.modals_by_id[element_id])? then @_state.modals[index] else false

        @_init = () =>

            modals = _.get '.pre-modal'
            (_m = @create(modal, (_t = _.get('#a-'+modal.getAttribute('id'))))
            @enable(_m)) for modal in modals if modals?

            @_state.init = true
            return @


class Modal extends CoreWidget

    template: [
        '<div id="{{<element_id}}-modal-dialog" style="opacity: 0;" class="fixed dropshadow modal-dialog{{config.rounded}} rounded{{/config.rounded}} none">',
            '<div id="{{&1}}-modal-fade" style="opacity: 0" class="modal-fade">',
                '<div id="{{&1}}-modal-content" class="modal-content">{{=html}}</div>',
                '<div id="{{&1}}-modal-ui" class="absolute modal-ui">',
                    '<div id="{{&1}}-modal-title" class="absolute modal-title">{{=title}}</div>',
                    '<div id="{{&1}}-modal-close" class="absolute modal-close">X</div>',
                '</div>',
            '</div>',
        '</div>'
    ].join('')

    constructor: (target, trigger, options) ->

        @_state =

            element_id: target.getAttribute('id')        # source div ID
            html: target.innerHTML
            trigger_id: trigger.getAttribute('id')
            overlay: null
            title: target.getAttribute('data-title')

            active: false
            init: false

            config:

                initial:                                # style props at animate start
                    width: '0'
                    height: '0'
                    top: window.innerHeight/2
                    left: window.innerHeight/2

                ratio:                                  # 0-1, final size vs. window inner
                    x: 0.4
                    y: 0.4

                size: {}                                # for fixed width/height: integers or percentages

                rounded: true
                calc: null

        @_state.config = _.extend(@_state.config, options)

        @id = @_state.element_id + '-modal-dialog'

        @internal =

            calc: () =>
                # returns prepared modal property object
                if @_state.config.calc?
                    return @_state.config.calc()

                css = {}
                wW = window.innerWidth
                wH = window.innerHeight
                r = @_state.config.ratio

                dW = @_state.config.size.width or Math.floor r.x*wW
                dH = @_state.config.size.height or Math.floor r.y*wH

                css.width = dW
                css.height = dH
                css.left = Math.floor((wW-dW)/2)
                css.top = Math.floor((wH-dH)/2)

                return css

            classify: (element, method) =>

                if element?
                    ecl = element.classList

                    if method is 'close' or not method?
                        ecl.remove('dropshadow')
                        ecl.remove('rounded')
                        ecl.add('none')
                        ecl.remove('block')

                        element.style.padding = '0px'
                        return element

                    else if method is 'open'
                        ecl.add('block')
                        ecl.remove('none')
                        ecl.add('dropshadow')
                        ecl.add('rounded')

                        element.style.padding = '10px'
                        return element

                else return false

        @make = () =>

            @template = new t(@constructor::template)
            df = _.create_doc_frag(@template.parse(@_state))
            document.body.appendChild(df)

            # style & customize modal dialogue
            dialog = _.get('#'+@id)
            content = dialog.find('modal-content')
            pre = _.get('#'+@_state.element_id)

            dialog.style[prop] = val + 'px' for prop, val of @_state.config.initial

            content.style.opacity = 1
            content.style.maxHeight = @internal.calc().height - 22 + 'px'

            pre.innerHTML = ''

            return dialog

        @open = (cback) =>
            if cback? and cback.preventDefault
                cback.preventDefault()
                cback.stopPropagation()
                cback = arguments[1] or null

            id = @_state.element_id
            dialog = _.get('#'+@id)
            close_x = dialog.find('#'+id+'-modal-close')
            @_state.active = true

            # extend default animation params with callbacks
            dialog_animation =
                callback: (d) =>
                    d.find('modal-fade').fadeIn()
                    return @internal.classify(d, 'open')

            # get final params
            final = @internal.calc()
            final.opacity = 1

            # show & bind close()
            dialog.animate final, dialog_animation

            _.bind(close_x, 'mousedown', @close)

            return if cback? then cback(@) else @

        @close = (cback) =>
            if cback? and cback.preventDefault
                cback.preventDefault()
                cback.stopPropagation()
                cback = arguments[1] or null

            _.unbind(_.get('#'+@_state.element_id+'-modal-close'), 'mousedown', @close)
            dialog = _.get('#'+@id)

            final = @_state.config.initial
            final.opacity = 0

            dialog.find('modal-fade').fadeOut()
            dialog.animate final,
                delay: 400
                complete: (d) =>
                    return @internal.classify(d, 'close')

            @_state.active = false
            return if cback? then cback(@) else @

        @_init = () =>

            dialog = @make()
            trigger = _.get(@_state.trigger_id)
            trigger.removeAttribute(if trigger.hasAttribute('href') then 'href' else 'data-href')
            @render = (html) =>
                _.get('modal-content', _.get('#'+@id)).innerHTML = html

            @resize = (e) =>
                if e.preventDefault
                    e.preventDefault()
                    e.stopPropagation()

                newcss = @internal.calc()
                modal = _.get('#'+@id)
                modal.style[prop] = val + 'px' for prop, val of newcss
                return

            window.addEventListener('resize', _.throttle(@resize, 350, false), true)

            @_state.init = true

            return @



@__apptools_preinit.abstract_base_classes.push Modal
@__apptools_preinit.abstract_base_classes.push ModalAPI
@__apptools_preinit.deferred_core_modules.push {module: ModalAPI, package: 'widgets'}