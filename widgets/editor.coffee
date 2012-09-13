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

            target = _.get(editor._state.element_id)
            _.bind(target, 'dblclick', editor.edit, false)

            return editor

        @disable = (editor) =>

            _.unbind(_.get(editor._state.element_id), 'dblclick')
            return editor

        @get = (element_id) =>

            return if (index = @_state.editors_by_id[element_id])? then @_state.editors[index] else false

        @_init = () =>

            editors = _.get '.mini-editable'
            @enable(@create(editor)) for editor in editors if editors?
            @_state.init = true

            return @

class Editor extends CoreWidget

    export: 'private'

    template: ['<div id="editor-pane-{{<_state.element_id}}" class="absolute editor">','<div id="editorstep-{{&1}}" class="editorstep"></div>','</div>'].join('')

    steps:
        edit: '<span class="rounded tools">{{@bundle}}<button class="editorbutton XMS" id="edit-cmd-{{<_key}}" value="{{&1}}">{{=_val}}</button>{{/bundle}}</span>'
        wait: '<span class="rounded notify loading spinner momentron">&#xf0045;</span>'
        done: '<span class="rounded yay momentron">&#xf0053;</span>'
        fail: '<span class="rounded error momentron">&#xf0054;</span>'

    bundles: [
        save:
            char: '&#x21;'
            command: null
    ,
        bold:
            char: 'B'
            command: () -> document.execCommand 'bold'
        underline:
            char: 'U'
            command: () -> document.execCommand 'underline'
        italic:
            char: 'I'
            command: () -> document.execCommand 'italic'
        clear_format:
            char: '&#x22;'
            command: () -> document.execCommand 'removeFormat'
        undo:
            char: '&#x23;'
            command: () -> document.execCommand 'undo'
        redo:
            char: '&#x24;'
            command: () -> document.execCommand 'redo'
        cut:
            char: '&#x26;'
            command: () -> document.execCommand 'cut'
        paste:
            char: '&#x25;'
            command: () -> document.execCommand 'paste'

    ,
        h1:
            char: 'h1'
            command: () -> document.execCommand 'heading', false, 'h1'
        h2:
            char: 'h2'
            command: () -> document.execCommand 'heading', false, 'h2'
        h3:
            char: 'h3'
            command: () -> document.execCommand 'heading', false, 'h3'
        font_color:
            char: '&#x28;'
            command: () ->
                c = _.to_hex prompt 'Please enter hex (#000000) or RGB (rgb(0,0,0)) values.'
                sel = if document.selection then document.selection() else window.getSelection()
                document.execCommand 'insertHTML', false, '<span style="color: '+c+';">'+sel+'</span>'
        font_size:
            char: '&#x28;'
            command: () ->
                s = prompt 'Please enter desired numerical pt size (i.e. 10)'
                sel = if document.selection then document.selection() else window.getSelection()
                document.execCommand 'insertHTML', false, '<span style="font-size: '+s+';">'+sel+'</span>'
        left:
            char: '&#x29;'
            command: () -> document.execCommand 'justifyLeft'
        center:
            char: '&#x2a;'
            command: () -> document.execCommand 'justifyCenter'
        right:
            char: '&#x2b;'
            command: () -> document.execCommand 'justifyRight'
        indent:
            char: '&#x2c;'
            command: () -> document.execCommand 'indent'
        outdent:
            char: '&#x2d;'
            command: () -> document.execCommand 'outdent'
        link:
            char: '&#x2e;'
            command: () ->
                t = if document.selection then document.selection() else window.getSelection()
                if t? and t.toString().match ///^http|www///
                    _t = t.toString()
                    t = prompt 'What link text do you want to display?'
                else if not t?
                    t = prompt 'What link text do you want to display?'

                l = _t or prompt 'What URL do you want to link to? (http://www...)'
                document.execCommand 'insertHTML', false, '<a href="'+_.strip_script l+'">'+t+'</a>'
    ]

    prep_bundle: (i) ->

        _b = @bundles.slice(0, i+1)
        bundle = {}
        commands = {}
        for b in _b
            for k, v of b
                bundle[k] = v.char
                commands[k] = v.command

        return [bundle, commands]

    constructor: (target, options) ->
        super()

        @_state =

            element_id: target.getAttribute('id')
            keyname: target.getAttribute('data-keyname') or null
            namespace: target.getAttribute('data-namespace') or null
            pane_id: null
            cached_content: null
            cached_templates: {}

            bundles: ['plain', 'basic', 'rich']

            step: 0
            active: false
            init: false

            config:
                animation: _.prep_animation()
                bundle: 'plain'

        @_state.config = _.extend true, @_state.config, options

        @id = 'editor-pane-' + @_state.element_id

        @ctrl = (e) =>
            if e? and e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            cmd = e.target.getAttribute('id').split('-').pop()
            return (if cmd is 'save' then @save.call(@, e) else @commands[cmd]())

        @callback = (cb) =>

            return if cb? and typeof cb is 'function' then cb.call(@) else @

        @render = () =>

            document.body.appendChild(_.create_doc_frag(@template.parse(@)))
            pane = _.get('#'+@id)
            step = pane.find('editorstep')

            @_state.step = 'edit'
            @template.t = @steps['edit']
            step.innerHTML = @template.parse(@)

            _w = pane.scrollWidth
            pane.style.right = (window.innerWidth - _w)/2 + 'px'

            _.bind(step.find('editorbutton'), 'click', @ctrl)

            return @render = (cb) =>
                pane = _.get(@_state.pane_id)
                step = pane.find('editorstep')
                step.innerHTML = @template.parse(@)

                _w = pane.scrollWidth
                pane.style.right = (window.innerWidth - _w)/2 + 'px'
                _.bind(step.find('editorbutton', 'click', @ctrl))

                return @callback(cb)

        @show = (cb) =>

            pane = _.get(@_state.pane_id)
            pane.classList.add('active')
            @_state.active = true
            return @callback(cb)

        @hide = (cb) =>

            pane = _.get(@_state.pane_id)
            pane.classList.remove('active')
            @_state.active = false
            return @callback(cb)

        @step = (name='edit', cb) =>

            @hide()
            setTimeout(@show, 350)

            @_state.step = name
            @template.t = @steps[name]
            return @render(cb)


        @edit = (e) =>

            if e? and e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            return @step 'edit', () =>
                el = _.get(@_state.element_id)
                _.unbind(el, 'dblclick', @edit)
                el.contentEditable = true
                @_state.cached_content = if @_state.config.bundle is 'plain' then el.innerText else el.innerHTML

                _.bind(document.body, 'dblclick', @save)
                el.focus()

        @save = (e) =>

            if e? and e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            pane = _.get(@_state.pane_id)
            el = _.get(@_state.element_id)
            el.contentEditable = false

            return @step 'wait', () =>
                html = if @_state.config.bundle is 'plain' then el.innerText else el.innerHTML
                cached_html = @_state.cached_content
                if html is cached_html
                    _.bind(el, 'dblclick', @edit)
                    return @hide()
                else
                    return $.apptools.api.content.save_snippet(
                        keyname: @_state.keyname
                        namespace: @_state.namespace
                        html: html
                    ).fulfill
                        success: (response) =>
                            return @step 'done', () =>
                                el.innerHTML = response.html
                                _.bind(el, 'dblclick', @edit)
                                _.unbind(document.body, 'dblclick')

                                setTimeout(@hide, 1500)
                                return @

                        failure: (error) =>
                            return @step 'fail', () =>
                                setTimeout(@edit, 1500)
                                return @

        @_init = () =>

            [@bundle, @commands] = @prep_bundle(_.indexOf(@_state.bundles, @_state.config.bundle))
            @commands.save = @save
            @steps = @constructor::steps
            @render()

            @_state.init = true

            return @

        return @



@__apptools_preinit.abstract_base_classes.push Editor
@__apptools_preinit.abstract_base_classes.push EditorAPI
@__apptools_preinit.deferred_core_modules.push {module: EditorAPI, package: 'widgets'}
