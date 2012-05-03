class Modal extends CoreWidget

    constructor: (target, trigger, options) ->

        @state =
            el: target
            trigger: trigger
            dialog: null
            overlay: null
            active: false
            init: false

        @defaults =
            start: # initial modal size & centered
                width: '0px'
                height: '0px'
                top: window.innerHeight/2 + 'px'
                left: window.innerHeight/2 + 'px'

            ratio: # proportional to browser window
                x: 0.4
                y: 0.4

            html: [ # modal template
                '<div id="modal-dialog" style="opacity: 0;" class="fixed dropshadow dialog">',
                    '<div id="modal-fade" style="opacity: 0">',
                        '<div id="modal-content">&nbsp;</div>',
                        '<span class="modal-ui" class="absolute">',
                            '<span id="modal-title" class="absolute"></span>',
                            '<span id="modal-close" class="absolute">X</span>',
                        '</span>',
                    '</div>',
                '</div>',
            ].join '\n'

            rounded: true # rounded corners?

        @config = $.extend true, @defaults, options

        @calc = () =>

            # returns prepared modal property object
            css = {}
            r = @config.ratio
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

            # make & append document fragment from template string
            range = document.createRange()
            range.selectNode @util.get('div').item 0 # select document as current node
            d = range.createContextualFragment @config.html # parse html string
            document.body.appendChild d

            # style & customize modal dialogue
            dialog = @util.get 'modal-dialog'
            title = @util.get 'modal-title'
            content = @util.get 'modal-content'
            close_x = @util.get 'modal-close'
            fade = @util.get 'modal-fade'
            id = target.getAttribute 'id'

            dialog.setAttribute 'id', 'modal-dialog-'+id
            dialog.classList.add 'rounded' if @config.rounded
            dialog.style[prop] = val for prop, val of @config.start

            content.setAttribute 'id', 'modal-content-'+id
            content.style.height = @calc().height
            content.innerHTML = target.innerHTML

            title.setAttribute 'id', 'modal-title-'+id
            title.innerHTML = target.getAttribute 'data-title'

            close_x.setAttribute 'id', 'modal-close-'+id
            fade.setAttribute 'id', 'modal-fade'+id

            # stash a reference to dialogue element
            @state.dialog = dialog.getAttribute 'id'

            return dialog

        @open = (dialog) =>

            @state.active = true

            # make/stash/append overlay
            o = @overlay 'modal'
            @state.overlay = o.getAttribute 'id'
            document.body.appendChild o

            # extend default animation params with callbacks
            dialogAnimation = overlayAnimation = @animation
            dialogAnimation.complete = () =>
                @util.bind @util.get('modal-close-'+target.getAttribute 'id'), 'mousedown', @close dialog
            overlayAnimation.complete = () =>
                @util.bind o, 'mousedown', @close dialog

            # get final params
            final = @calc()
            final.opacity = 1

            # show
            $(o).animate opacity: 0.5, overlayAnimation
            $(dialog).animate final, dialogAnimation

            return dialog

        @close = (dialog) =>

            @state.active = false

            overlay = @util.get @state.overlay
            midpoint =
                width: window.innerWidth
                height: '0px'
                left: '0px'
                right: '0px'
                opacity: 0.5

            # customize animations - since it's all nested callbacks, go inside out
            fadeAnim = midpointAnim = finalAnim = overlayAnim = @animation

            overlayAnim.duration = fadeAnim.duration = midpointAnim.duration = 300
            finalAnim.duration = 250

            overlayAnim.complete = () ->
                document.removeChild overlay
                document.removeChild modal

            midpointAnim.complete = () ->
                $(dialog).animate opacity: 0, finalAnim
                $(overlay).animate opacity: 0, overlayAnim

            fadeAnim.complete = () ->
                setTimeout () ->
                    m.classList.remove 'dropshadow'
                    m.classList.remove 'rounded'
                    m.style.padding = '0px'
                , 150
                $(dialog).animate midpoint, midpointAnim


            @util.get('modal-content-'+target.getAttribute 'id').style.overflow = 'hidden' # disable scroll during animation
            @util.get('modal-fade-'+target.getAttribute 'id').animate opacity: 0, fadeAnim # hide it!

            return dialog

    _init: () ->

        dialog = @make()
        document.body.appendChild dialog

        @state.init = true
        return $.apptools.events.trigger 'MODAL_READY', @



class ModalAPI extends CoreWidgetAPI

    @mount = 'modal'
    @events = ['MODAL_READY', 'MODAL_API_READY']

    constructor: (apptools, widget, window) ->

        @state =
            modals: []
            modals_by_id: {}
            next: modals.length

        @create = (target, trigger, options={}) =>

            modal = new Modal target, trigger, options
            @state.modals.push modal
            @state.modals_by_id[modal.state.el.getAttribute 'id'] = @state.next

            return modal

        @destroy = (modal) =>

            id = modal.state.el.getAttribute 'id'
            dialog = document.getElementById(modal.state.dialog)

            @state.modals.splice @state.modals_by_id[id], 1
            delete @state.modals_by_id[id]

            document.removeChild dialogue
            return modal

        @enable = (modal) =>

            trigger = modal.state.trigger
            @prime {trigger: @util.get modal.state.dialog}, modal.open
            return modal

        @disable = (modal) =>

            @unprime [modal.state.trigger]
            return modal

_init: (apptools) ->

    modals = @util.get 'modal'
    for modal in modals
        do (modal) =>
            modal = @create modal, @util.get 'a-'+modal.getAttribute 'id'
            modal = @enable modal

    return apptools.events.trigger 'MODAL_API_READY', @



@__apptools_preinit.abstract_base_classes.push Modal
@__apptools_preinit.abstract_base_classes.push ModalAPI
@__apptools_preinit.deferred_core_modules.push {module: ModalAPI, package: 'widgets'}