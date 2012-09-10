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

            options ?= if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            modal = new Modal(target, trigger, options)
            id = modal._state.cached_id

            @_state.modals_by_id[id] = @_state.modals.push(modal) - 1

            return if callback? then callback?(modal._init()) else modal._init()

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
            _.bind(trigger, 'mousedown', modal.open, false)

            return modal

        @disable = (modal) =>

            _.unbind(_.get(modal._state.trigger_id))

            return modal

        @get = (element_id) =>

            return if (index = @_state.modals_by_id[element_id])? then @_state.modals[index] else false

        @_init = () =>

            modals = _.get '.pre-modal'
            (_m = @create(modal, (_t = _.get('a-'+modal.getAttribute('id'))))
            @enable(_m)) for modal in modals if modals?

            @_state.init = true
            return @


class Modal extends CoreWidget

    constructor: (target, trigger, options) ->

        @_state =

            cached_id: target.getAttribute('id')        # source div ID
            cached_html: null
            trigger_id: trigger.getAttribute('id')
            element_id: null
            overlay: null

            active: false
            init: false

            config:

                initial:                                # style props at animate start
                    width: '0px'
                    height: '0px'
                    top: window.innerHeight/2 + 'px'
                    left: window.innerHeight/2 + 'px'

                ratio:                                  # 0-1, final size vs. window inner
                    x: 0.4
                    y: 0.4

                template: [                             # someday I'll write the render API
                    '<div id="modal-dialog" style="opacity: 0;" class="fixed dropshadow">',
                        '<div id="modal-fade" style="opacity: 0">',
                            '<div id="modal-content">&nbsp;</div>',
                            '<div id="modal-ui" class="absolute">',
                                '<div id="modal-title" class="absolute"></div>',
                                '<div id="modal-close" class="absolute">X</div>',
                            '</div>',
                        '</div>',
                    '</div>'
                ].join('\n')

                rounded: true
                calc: null

        @_state.config = _.extend(@_state.config, options)

        @internal =

            calc: () =>
                # returns prepared modal property object
                if @_state.config.calc?
                    return @_state.config.calc()
                else
                    css = {}
                    r = @_state.config.ratio
                    wW = window.innerWidth
                    wH = window.innerHeight
                    dW = Math.floor r.x*wW
                    dH = Math.floor r.y*wH

                    css.width = dW+'px'
                    css.height = dH+'px'
                    css.left = Math.floor((wW-dW)/2)+'px'
                    css.top = Math.floor((wH-dH)/2)+'px'

                    return css

            classify: (element, method) =>

                if method is 'close' or not method?

                    ecl.remove('dropshadow') if _.in_array((ecl=element.classList), 'dropshadow')
                    ecl.remove('rounded') if _.in_array(ecl, 'rounded')
                    element.style.padding = '0px'
                    return element

                else if method is 'open'

                    ecl.add('dropshadow') if not _.in_array((ecl=element.classList), 'dropshadow')
                    ecl.add('rounded') if not _.in_array(ecl, 'rounded') and @_state.config.rounded
                    element.style.padding = '10px'
                    return element

                else if not element?

                    return false

        @make = () =>

            template = @_state.config.template

            # make & append document fragment from template string
            range = document.createRange()
            range.selectNode(document.getElementsByTagName('div').item(0))  # select document body
            d = range.createContextualFragment(template)                    # parse html string
            document.body.appendChild d

            # style & customize modal dialogue
            dialog = _.get 'modal-dialog'
            title = _.get 'modal-title'
            content = _.get 'modal-content'
            ui = _.get 'modal-ui'
            close_x = _.get 'modal-close'
            fade = _.get 'modal-fade'
            id = @_state.cached_id
            pre = _.get(id)

            dialog.classList.add dialog.getAttribute 'id'
            dialog.setAttribute 'id', id+'-modal-dialog'
            dialog.classList.add 'rounded' if @_state.config.rounded
            dialog.style[prop] = val for prop, val of @_state.config.initial

            content.classList.add content.getAttribute 'id'
            content.setAttribute 'id', id+'-modal-content'
            content.style[prop] = val for prop, val of pre.style
            content.style.opacity = 1
            content.style.height = @internal.calc().height
            content.innerHTML = (t = _.get(id)).innerHTML

            title.classList.add title.getAttribute 'id'
            title.setAttribute 'id', id+'-modal-title'
            title.innerHTML = t.getAttribute 'data-title'

            ui.classList.add ui.getAttribute 'id'
            ui.setAttribute 'id', id+'-modal-ui'

            close_x.classList.add close_x.getAttribute 'id'
            close_x.setAttribute 'id', id+'-modal-close'

            fade.classList.add fade.getAttribute 'id'
            fade.setAttribute 'id', id+'-modal-fade'

            # stash a reference to dialogue element
            @_state.element_id = dialog.getAttribute 'id'
            @_state.cached_html = t.innerHTML
            t.innerHTML = ''

            return dialog

        @open = (callback) =>

            id = @_state.cached_id
            dialog = _.get(@_state.element_id)
            close_x = _.get(id+'-modal-close')
            @_state.active = true

            # overlay!
            #overlay = @_state.overlay or @prepare_overlay('modal')
            #@_state.overlay = overlay
            #if not overlay.parentNode?
                #document.body.appendChild(overlay)

            # extend default animation params with callbacks
            fade_animation = _.prep_animation()
            dialog_animation = _.prep_animation()
            #overlay_animation = @animation

            dialog_animation.complete = () =>
                @internal.classify(dialog, 'open')
                $('#'+id+'-modal-fade').animate opacity: 1, fade_animation
                return (if callback? then callback.call(@) else @)

            # get final params
            final = @internal.calc()
            final.opacity = 1

            # show & bind close()
            dialog.style.display = 'block'
            #overlay.style.display = 'block'

            #$(overlay).animate opacity: 0.5, overlay_animation
            $(dialog).animate final, dialog_animation

            _.bind(close_x, 'mousedown', @close)

            return @

        @close = (callback) =>

            id = @_state.cached_id

            #overlay = @_state.overlay
            dialog = _.get @_state.element_id

            _.unbind(_.get(id+'-modal-close'), 'mousedown')

            midpoint = _.extend({}, @_state.config.initial, opacity: 0.5)


            _.get(id+'-modal-content').style.overflow = 'hidden' # disable scroll during animation
            $('#'+id+'-modal-fade').animate({opacity: 0}, {
                duration: 300,
                complete: () =>
                    @internal.classify(dialog, 'close')

                    $(dialog).animate(midpoint, {
                        duration: 200,
                        complete: () =>
                            $(dialog).animate({opacity: 0}, {
                                duration: 250,
                                complete: () =>
                                    dialog.style.display = 'none'
                                    dialog.style[prop] = val for prop, val of @_state.config.initial
                                    @_state.active = false

                                    return if callback? then callback?(@) else @
                                }
                            )
                        }
                    )
                }
            )

        @fade = (opacity, cback) =>
            id = @_state.cached_id
            $('#'+id+'modal-fade').animate(opacity: opacity, {duration: 300, complete: cback})
            return @
        @fadeout = (cback) =>
            return @fade(0, cback)
        @fadein = (cback) =>
            return @fade(1, cback)

        @_init = () =>

            dialog = @make()
            _.get(@_state.trigger_id).removeAttribute('href')
            @render = (html) =>
                _.get('modal-content', _.get(@_state.element_id)).innerHTML = html

            @resize = (e) =>
                if e.preventDefault
                    return false if @ts? and @ts is e.timeStamp
                    @ts = e.timeStamp
                    e.preventDefault()
                    e.stopPropagation()

                newcss = @internal.calc()
                modal = _.get('#'+@_state.element_id)
                modal.style[prop] = val for prop, val of newcss
                return

            _.bind(window, 'resize', _.throttle(@resize, 350, false), true)

            @_state.init = true

            return @



@__apptools_preinit.abstract_base_classes.push Modal
@__apptools_preinit.abstract_base_classes.push ModalAPI
@__apptools_preinit.deferred_core_modules.push {module: ModalAPI, package: 'widgets'}