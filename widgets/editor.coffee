# AppTools Editor Widget
class Editor extends CoreWidget

    constructor: (target, options) ->

        @state =
            el: target
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
                        c = @util.toHex prompt 'Please enter hex (#000000) or RGB (rgb(0,0,0)) values.'
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
                        document.execCommand 'insertHTML', false, '<a href="'+@util.stripScript l+'">'+t+'</a>'

            bundle: 'rich'

        @config = $.extend true, @defaults, options

        @make = () =>

            pane = document.createElement 'div'
            pane.setAttribute 'id', 'editor-pane-'+target.getAttribute 'id'
            pane.style.width = '150px'
            pane.style.left = @util.getOffset(target).left - pane.style.width
            pane.style.top = @util.getOffset(target).top
            pane.style.opacity = 0

            features = @config.bundles.basic
            if @config.bundle is 'rich'
                features[k] = v for k, v of @config.bundles.rich

            for feature, command of features
                do (feature, command) =>
                    button = document.createElement 'button'
                    button.value = button.innerHTML = feature
                    button.className = 'editorbutton'
                    @util.bind button, 'mousedown', command
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

            @show @util.get @state.pane
            target.contentEditable = true
            @state.active = true

            return target.focus()

        @save = () =>

            @hide @util.get @state.pane
            target.contentEditable = false
            return @state.active = false


    _init: () ->

        pane = @make()
        document.body.appendChild pane

        @state.init = true
        return $.apptools.events.trigger 'EDITOR_READY', @


class EditorAPI extends CoreWidgetAPI

    @mount = 'editor'
    @events = ['EDITOR_READY', 'EDITOR_API_READY']

    constructor: (apptools, widget, window) ->

        @state =
            editors: []
            editors_by_id: {}
            next: editors.length

        @create = (target, options={}) =>

            editor = new Editor target, options
            @state.editors.push editor
            @state.editors_by_id[editor.state.el.getAttribute 'id'] = @state.next

            return editor

        @destroy = (editor) =>

            id = editor.state.el.getAttribute 'id'
            pane = document.getElementById editor.state.pane

            @state.editors.splice @state.pickers_by_id[id], 1
            delete @state.pickers_by_id[id]

            document.removeChild pane
            return editor

        @enable = (editor) =>

            el = editor.state.el
            @prime {el: @util.get editor.state.pane}, editor.edit
            return editor

        @disable = (editor) =>

            @unprime [editor.state.el]
            return editor


    _init: (apptools) ->

        editors = @util.get 'edit'
        for editor in editors
            do (editor) ->
                editor = @create editor

                # don't enable since saving is still stubbed
                #editor = @enable editor

        return apptools.events.trigger 'EDITOR_API_READY', @



@__apptools_preinit.abstract_base_classes.push Editor
@__apptools_preinit.abstract_base_classes.push EditorAPI
@__apptools_preinit.deferred_core_modules.push {module: EditorAPI, package: 'widgets'}