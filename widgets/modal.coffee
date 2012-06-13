class ModalAPI extends CoreWidgetAPI

    @mount = 'modal'
    @events = ['MODAL_READY', 'MODAL_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            modals: []
            modals_by_id: {}
            next: 0
            init: false

        @create = (target, trigger, options={}) =>

            modal = new Modal(target, trigger, options)

            @_state.modals_by_id[modal._state.element_id] = @_state.next
            @_state.modals.push(modal)
            @_state.next++

            return modal._init()

        @destroy = (modal) =>

            id = modal._state.element_id

            @_state.modals.splice @_state.modals_by_id[id], 1
            delete @_state.modals_by_id[id]

            document.body.removeChild(Util.get(id))

            return modal

        @enable = (modal) =>

            trigger = Util.get(modal._state.trigger_id)
            console.log("TRIGGER: "+trigger.getAttribute('id'))
            Util.bind(trigger, 'mousedown', modal.open, false)

            return modal

        @disable = (modal) =>

            Util.unbind(Util.get(modal._state.trigger_id))

            return modal

        @_init = () =>

            modals = Util.get 'pre-modal'
            @enable(@create(modal, Util.get('a-'+modal.getAttribute('id')))) for modal in modals

            return @_state.init = true




class Modal extends CoreWidget

    constructor: (target, trigger) ->

        @_state =

            cached_id: target.getAttribute('id')        # source div ID
            trigger_id: trigger.getAttribute('id')
            element_id: null
            overlay_id: null

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
                    '<div id="modal-dialog" style="opacity: 0;" class="fixed dropshadow modal">',
                        '<div id="modal-fade" style="opacity: 0">',
                            '<div id="modal-content">&nbsp;</div>',
                            '<span class="modal-ui" class="absolute">',
                                '<span id="modal-title" class="absolute"></span>',
                                '<span id="modal-close" class="absolute">X</span>',
                            '</span>',
                        '</div>',
                    '</div>'
                ].join('\n')

                rounded: true

        @_state.config = Util.extend(true, @_state.config, JSON.parse(target.getAttribute('data-options')))

        @calc = () =>

            # returns prepared modal property object
            css = {}
            r = @_state.config.ratio
            wW = window.innerWidth
            wH = window.innerHeight
            dW = Math.floor r.x*wW
            dH = Math.floor r.y*wH

            css.width = dW+'px'
            css.height = dH+'px'
            css.left = Math.floor (wW-dW)/2
            css.top = Math.floor (wH-dH)/2

            return css

        @make = () =>

            template = @_state.config.template

            # make & append document fragment from template string
            range = document.createRange()
            range.selectNode(doc = document.getElementsByTagName('div').item(0))    # select document
            d = range.createContextualFragment(template)                            # parse html string
            document.body.appendChild d

            # style & customize modal dialogue
            dialog = Util.get 'modal-dialog'
            title = Util.get 'modal-title'
            content = Util.get 'modal-content'
            close_x = Util.get 'modal-close'
            fade = Util.get 'modal-fade'
            id = @_state.cached_id

            dialog.setAttribute 'id', 'modal-dialog-'+id
            dialog.classList.add 'rounded' if @_state.config.rounded
            dialog.style[prop] = val for prop, val of @_state.config.initial

            content.setAttribute 'id', 'modal-content-'+id
            content.style.height = @calc().height
            content.innerHTML = target.innerHTML

            title.setAttribute 'id', 'modal-title-'+id
            title.innerHTML = target.getAttribute 'data-title'

            close_x.setAttribute 'id', 'modal-close-'+id
            fade.setAttribute 'id', 'modal-fade-'+id

            # stash a reference to dialogue element
            @_state.element_id = dialog.getAttribute 'id'

            return dialog

        @open = () =>

            dialog = Util.get(@_state.element_id)
            @_state.active = true

            # overlay!
            o = @prepare_overlay('modal')
            @_state.overlay_id = o.getAttribute 'id'
            document.body.appendChild o

            # extend default animation params with callbacks
            dialog_animation = overlay_animation = @animation
            dialog_animation.complete = () =>
                Util.bind(c = Util.get('modal-close-'+@_state.cached_id), 'mousedown', @close)
            overlay_animation.complete = () =>
                Util.bind(o, 'mousedown', @close)

            # get final params
            final = @calc()
            final.opacity = 1
            console.log("FINAL: "+final)

            # show
            $(o).animate opacity: 0.5, overlay_animation
            $(dialog).animate final, dialog_animation

            return dialog

        @close = () =>

            @_state.active = false

            overlay = Util.get @_state.overlay_id
            dialog = Util.get @_state.element_id

            midpoint =
                width: window.innerWidth
                height: '0px'
                left: '0px'
                right: '0px'
                opacity: 0.5

            # customize animations - since it's all nested callbacks, go inside out
            fade_anim = midpoint_anim = final_anim = overlay_anim = @animation

            overlay_anim.duration = fade_anim.duration = midpoint_anim.duration = 300
            final_anim.duration = 250

            overlay_anim.complete = () ->
                document.removeChild overlay
                document.removeChild dialog

            midpoint_anim.complete = () ->
                $(dialog).animate opacity: 0, finalAnim
                $(overlay).animate opacity: 0, overlayAnim

            fade_anim.complete = () ->
                setTimeout () ->
                    m.classList.remove 'dropshadow'
                    m.classList.remove 'rounded'
                    m.style.padding = '0px'
                , 150
                $(dialog).animate midpoint, midpointAnim


            Util.get('modal-content-'+@_state.cached_id).style.overflow = 'hidden' # disable scroll during animation
            $('modal-fade-'+@_state.cached_id).animate opacity: 0, fade_anim # hide it!

            return dialog

        @_init = () =>

            dialog = @make()
            trigger.removeAttribute('href')

            @_state.init = true
            $.apptools.events.trigger 'MODAL_READY', @

            return @



@__apptools_preinit.abstract_base_classes.push Modal
@__apptools_preinit.abstract_base_classes.push ModalAPI
@__apptools_preinit.deferred_core_modules.push {module: ModalAPI, package: 'widgets'}