## AppTools content editor widget & api
class EditorAPI extends CoreWidgetAPI

    @mount = 'editor'
    @events = ['EDITOR_READY', 'EDITOR_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            editors: []
            editors_by_id: {}
            init: false


        @create = (target) =>

            options = if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            editor = new Editor target, options
            id = editor._state.element_id

            @_state.editors_by_id[id] = @_state.editors.push(editor) - 1

            return editor._init()

        @destroy = (editor) =>

            id = editor._state.element_id
            @_state.editors.splice(@_state.editors_by_id[id], 1)
            delete @_state.editors_by_id[id]

            return editor

        @enable = (editor) =>

            target = Util.get(editor._state.element_id)
            Util.bind(target, 'mousedown', editor.open, false)

            return editor

        @disable = (editor) =>

            Util.unbind(Util.get(editor._state.element_id))

            return editor


        @_init = () =>

            editors = Util.get 'mini-editable'
            for editor in editors
                do (editor) =>

                    # instantiate editor
                    editor = @create editor

                    # bind commands & allow editing - stubbed
                    #editor = @enable editor

            return apptools.events.trigger 'EDITOR_API_READY', @


class Editor extends CoreWidget

    constructor: (target, options) ->

        @state =

            element_id: target.getAttribute('id')
            pane: null
            active: false
            init: false

        @defaults =
            bundles:
                basic:
                    b: () -> document.execCommand 'bold'
                    u: () -> document.execCommand 'underline'
                    i: () -> document.execCommand 'italic'
                    clear: () -> document.execCommand 'removeFormat'
                    undo: () -> document.execCommand 'undo'
                    redo: () -> document.execCommand 'redo'
                    cut: () -> document.execCommand 'cut'
                    paste: () -> document.execCommand 'paste'

                rich:
                    h1: () -> document.execCommand 'heading', false, 'h1'
                    h2: () -> document.execCommand 'heading', false, 'h2'
                    h3: () -> document.execCommand 'heading', false, 'h3'
                    fontColor: () =>
                        c = Util.toHex prompt 'Please enter hex (#000000) or RGB (rgb(0,0,0)) values.'
                        sel = document.selection() or window.getSelection()
                        document.execCommand 'insertHTML', false, '<span style="color: '+c+';">'+sel+'</span>'
                    fontSize: () =>
                        s = prompt 'Please enter desired numerical pt size (i.e. 10)'
                        sel = document.selection() or window.getSelection()
                        document.execCommand 'insertHTML', false, '<span style="font-size: '+s+';">'+sel+'</span>'
                    left: () -> document.execCommand 'justifyLeft'
                    right: () -> document.execCommand 'justifyRight'
                    center: () -> document.execCommand 'justifyCenter'
                    indent: () -> document.execCommand 'indent'
                    outdent: () -> document.execCommand 'outdent'
                    link: () =>
                        t = document.selection() or window.getSelection()
                        if t? and t.match ///^http|www///
                            _t = t
                            t = prompt 'What link text do you want to display?'
                        else if not t?
                            t = prompt 'What link text do you want to display?'

                        l = _t or prompt 'What URL do you want to link to? (http://www...)'
                        document.execCommand 'insertHTML', false, '<a href="'+Util.strip_script l+'">'+t+'</a>'

            bundle: 'rich'

        @config = $.extend true, @defaults, options

        @make = () =>

            pane = document.createElement 'div'
            pane.setAttribute 'id', 'editor-pane-'+target.getAttribute 'id'
            pane.style.width = '150px'
            pane.style.left = Util.getOffset(target).left - pane.style.width
            pane.style.top = Util.getOffset(target).top
            pane.style.opacity = 0

            features = @config.bundles.basic
            if @config.bundle is 'rich'
                features[k] = v for k, v of @config.bundles.rich

            for feature, command of features
                do (feature, command) =>
                    button = document.createElement 'button'
                    button.value = button.innerHTML = feature
                    button.className = 'editorbutton'
                    Util.bind button, 'mousedown', command
                    pane.appendChild button

            document.body.appendChild pane

            # stash pane reference
            @state.pane = pane.getAttribute 'id'

            return pane

        @show = (pane) =>

            return $(pane).animate opacity: 1, @animation

        @hide = (pane) =>

            return $(pane).animate opacity: 0, @animation

        @edit = () =>

            @show Util.get @state.pane
            target.contentEditable = true
            @state.active = true

            return target.focus()

        @save = () =>

            @hide Util.get @state.pane
            target.contentEditable = false
            return @state.active = false


    _init: () ->

        pane = @make()
        document.body.appendChild pane

        @state.init = true
        return $.apptools.events.trigger 'EDITOR_READY', @



@__apptools_preinit.abstract_base_classes.push Editor
@__apptools_preinit.abstract_base_classes.push EditorAPI
@__apptools_preinit.deferred_core_modules.push {module: EditorAPI, package: 'widgets'}