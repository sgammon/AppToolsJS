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
            snippet_keyname: target.getAttribute('data-keyname') or null
            snippet_namespace: target.getAttribute('data-namespace') or null
            pane_id: null
            active: false
            init: false

            config:
                bundles:
                    plain:
                        save:
                            char: '&#x21;'
                            command: () => return @save()
                    basic:
                        b:
                            char: 'B'
                            command: () => document.execCommand 'bold'
                        u:
                            char: 'U'
                            command: () => document.execCommand 'underline'
                        i:
                            char: 'I'
                            command: () => document.execCommand 'italic'
                        clear:
                            char: '&#x22;'
                            command: () => document.execCommand 'removeFormat'
                        undo:
                            char: '&#x23;'
                            command: () => document.execCommand 'undo'
                        redo:
                            char: '&#x24;'
                            command: () => document.execCommand 'redo'
                        cut:
                            char: '&#x25;'
                            command: () => document.execCommand 'cut'
                        paste:
                            char: '&#x26;'
                            command: () => document.execCommand 'paste'

                    rich:
                        h1:
                            char: 'h1'
                            command: () => document.execCommand 'heading', false, 'h1'
                        h2:
                            char: 'h2'
                            command: () => document.execCommand 'heading', false, 'h2'
                        h3:
                            char: 'h3'
                            command: () => document.execCommand 'heading', false, 'h3'
                        fontColor:
                            char: '&#x28;'
                            command: () =>
                                c = Util.to_hex prompt 'Please enter hex (#000000) or RGB (rgb(0,0,0)) values.'
                                sel = if document.selection then document.selection() else window.getSelection()
                                document.execCommand 'insertHTML', false, '<span style="color: '+c+';">'+sel+'</span>'
                        fontSize:
                            char: '&#x28;'
                            command: () =>
                                s = prompt 'Please enter desired numerical pt size (i.e. 10)'
                                sel = if document.selection then document.selection() else window.getSelection()
                                document.execCommand 'insertHTML', false, '<span style="font-size: '+s+';">'+sel+'</span>'
                        left:
                            char: '&#x29;'
                            command: () => document.execCommand 'justifyLeft'
                        right:
                            char: '&#x2a;'
                            command: () => document.execCommand 'justifyRight'
                        center:
                            char: '&#x2b;'
                            command: () => document.execCommand 'justifyCenter'
                        indent:
                            char: '&#x2c;'
                            command: () => document.execCommand 'indent'
                        outdent:
                            char: '&#x2d;'
                            command: () => document.execCommand 'outdent'
                        link:
                            char: '&#x2e;'
                            command: () =>
                                t = if document.selection then document.selection() else window.getSelection()
                                if t? and t.toString().match ///^http|www///
                                    _t = t.toString()
                                    t = prompt 'What link text do you want to display?'
                                else if not t?
                                    t = prompt 'What link text do you want to display?'

                                l = _t or prompt 'What URL do you want to link to? (http://www...)'
                                document.execCommand 'insertHTML', false, '<a href="'+Util.strip_script l+'">'+t+'</a>'

                bundle: 'plain'

                width: 150

        @_state.config = Util.extend true, @_state.config, options

        @make = () =>

            t = Util.get(t_id = @_state.element_id)
            width = @_state.config.width

            pane = document.createElement 'div'
            pane.setAttribute 'id', (pane_id = 'editor-pane-'+t_id)
            pane.classList.add 'absolute'
            pane.style.padding = 10 + 'px'
            pane.style.width = t.offsetWidth + 'px'
            pane.style.zIndex = 1
            pane.style.opacity = 0

            features = @_state.config.bundles.plain
            if @_state.config.bundle is 'rich' or 'basic'
                features[ke] = va for ke, va of @_state.config.bundles.basic
            if @_state.config.bundle is 'rich'
                features[k] = v for k, v of @_state.config.bundles.rich

            _button = (f, c) =>
                button = document.createElement 'button'
                button.innerHTML = command.char
                button.className = 'editorbutton XMS'
                Util.bind button, 'mousedown', command.command
                pane.appendChild button

            _button(feature, command) for feature, command of features

            _off = Util.get_offset(t)
            _h = pane.scrollHeight

            document.body.appendChild pane
            pane.style.right = window.innerWidth - (_off.left + t.scrollWidth) + 'px'
            pane.style.top = _off.top - _h + 'px'

            # stash pane reference
            @_state.pane_id = pane_id

            return pane

        @show = () =>

            (p=Util.get(@_state.pane_id)).style.zIndex = 9990
            $(p).animate opacity: 1, (Util.prep_animation())
            return @

        @hide = () =>


            (p=Util.get(@_state.pane_id)).style.zIndex = 1
            $(p).animate opacity: 0, (Util.prep_animation())
            return @

        @edit = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            @show()
            (el = Util.get(@_state.element_id)).contentEditable = true
            @_state.active = true

            Util.bind(document.body, 'dblclick', @save)
            el.focus()

            return @

        @save = (e) =>

            if e? and e.preventDefault?
                e.preventDefault
                e.stopPropagation

            pane = document.getElementById(@_state.pane_id)
            $(pane).animate
                opacity: 0
            ,
                duration: 200
                complete: () =>
                    pane.innerHTML = '<span class="loading spinner momentron">&#xf0045;</span>'
                    $(pane).animate
                        opacity: 1
                    ,
                        duration: 200

            console.log('Saving snippet...')
            html = Util.get(@_state.element_id).innerHTML

            $.apptools.api.content.save_snippet(
                keyname: @_state.snippet_keyname
                namespace: @_state.snippet_namespace
                html: html
            ).fulfill
                success: (response) =>
                    $(pane).animate
                        opacity: 0
                    ,
                        duration: 200
                        complete: () =>
                            pane.innerHTML = '<span class="momentron">&#xf0053;</span>'
                            pane.style.color = '#bada55'
                            $(pane).animate
                                opacity: 1
                            ,
                                duration: 200
                                complete: () =>
                                    setTimeout(() =>
                                        @hide()
                                    , 400)

                    (el = Util.get(@_state.element_id)).contentEditable = false
                    @_state.active = false

                    Util.unbind(document.body, 'dblclick')

                failure: (error) =>
                    $(pane).animate
                        opacity: 0
                    ,
                        duration: 200
                        complete: () =>
                            pane.innerHTML = '<span class="momentron">&#xf0054;</span>'
                            pane.style.color = '#f00'
                            $(pane).animate
                                opacity: 1
                            ,
                                duration: 200
                                complete: () =>
                                    setTimeout(() =>
                                        pane.innerHTML = @make().innerHTML
                                        @hide()
                                    , 400)

            return @

        @_init = () ->

            pane = @make()
            document.body.appendChild pane

            @_state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Editor
@__apptools_preinit.abstract_base_classes.push EditorAPI
@__apptools_preinit.deferred_core_modules.push {module: EditorAPI, package: 'widgets'}