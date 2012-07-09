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
            Util.bind(target, 'dblclick', editor.edit, false)

            return editor

        @disable = (editor) =>

            Util.unbind(Util.get(editor._state.element_id), 'dblclick')

            return editor


        @_init = () =>

            editors = Util.get 'mini-editable'
            @enable(@create(editor)) for editor in editors if editors?

            return @

class Editor extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute('id')
            pane_id: null
            active: false
            init: false

            config:
                bundles:
                    plain:
                        save: () -> return @save()
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

                width: 150

        @_state.config = Util.extend true, @_state.config, options

        @make = () =>

            t = Util.get(t_id = @_state.element_id)
            width = @_state.config.width

            pane = document.createElement 'div'
            pane.setAttribute 'id', (pane_id = 'editor-pane-'+t_id)
            pane.classList.add 'absolute'
            pane.style.width = width + 'px'
            pane.style.left = ((t_off = Util.get_offset(t)).left - width) + 'px'
            pane.style.top = t_off.top + 'px'
            pane.style.zIndex = '9990'
            pane.style.opacity = 0

            features = @_state.config.bundles.plain
            if @_state.config.bundle is 'rich'
                features[k] = v for k, v of @_state.config.bundles.rich

            (button = document.createElement 'button'
            button.value = button.innerHTML = feature
            button.className = 'editorbutton'
            Util.bind button, 'mousedown', command
            pane.appendChild button) for feature, command of features

            document.body.appendChild pane

            # stash pane reference
            @_state.pane_id = pane_id

            return pane

        @show = () =>

            $('#'+(p=@_state.pane_id)).animate opacity: 1, (Util.prep_animation())
            return @

        @hide = () =>

            $('#'+@_state.pane_id).animate opacity: 0, (Util.prep_animation())
            return @

        @edit = () =>

            @show()
            (el = Util.get(@_state.element_id)).contentEditable = true
            @_state.active = true

            Util.bind(el, 'dblclick', @save)
            el.focus()

            return @

        @save = () =>

            console.log('Saving...')

            @hide()
            (el = Util.get(@_state.element_id)).contentEditable = false
            @_state.active = false

            Util.unbind(el, 'dblclick')

            return @

        @_init = () ->

            pane = @make()
            document.body.appendChild pane

            @_state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Editor
@__apptools_preinit.abstract_base_classes.push EditorAPI
@__apptools_preinit.deferred_core_modules.push {module: EditorAPI, package: 'widgets'}