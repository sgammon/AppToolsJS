## AppTools content editor widget & api
class EditorAPI extends WidgetAPI

    @mount = 'editor'
    @events = ['EDITOR_READY', 'EDITOR_API_READY']

    enable: (editor) ->

        _.get(editor._state.element_id).addEventListener('dblclick', editor.edit, false)

        return editor

    disable: (editor) ->

        _.get(editor._state.element_id).removeEventListener('dblclick', editor.edit, false)
        return editor

    constructor: (apptools, widget, window) ->

        super(apptools, widget, window)

        @init = () =>
            editors = _.get '.mini-editable'
            @enable(@create(editor)) for editor in editors if editors?
            @state.init = true

            delete @init
            return @

        return @

class Editor extends CoreWidget

    export: 'private'

    template: ['<div id="editor-pane-{{<_state.element_id}}" class="absolute editor">','<div id="editorstep-{{&1}}" class="editorstep"></div>','</div>'].join('')

    steps:
        edit: '<span class="rounded tools">{{@bundle}}<button class="editorbutton XMS" id="edit-cmd-{{=_key}}" value="{{=_key}}">{{=_val}}</button>{{/bundle}}</span>'
        wait: '<span class="rounded tools"><span class="loading spinner momentron">&#xf0045;</span></span>'
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

        @state =

            element_id: target.getAttribute('id')
            keyname: target.getAttribute('data-keyname') or null
            namespace: target.getAttribute('data-namespace') or null
            pane_id: 'editor-pane-'+target.getAttribute('id')
            cached_content: null
            cached_templates: {}

            bundles: ['plain', 'basic', 'rich']

            step: 0
            timer: null
            active: false
            init: false

            config: _.extend(
                animation: _.prep_animation()
                bundle: 'plain'
            , options)

        @id = 'editor-pane-' + @state.element_id

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

            @state.step = 'edit'
            @template.t = @steps['edit']
            step.innerHTML = @template.parse(@)

            _w = pane.scrollWidth
            pane.style.right = (window.innerWidth - _w)/2 + 'px'

            _.bind(step.find('editorbutton'), 'click', @ctrl)

            return @render = (cb) =>
                pane = _.get(@state.pane_id)
                step = pane.find('editorstep')
                step.innerHTML = @template.parse(@)

                _w = pane.scrollWidth
                pane.style.right = (window.innerWidth - _w)/2 + 'px'
                _.bind(step.find('.editorbutton'), 'click', @ctrl)

                return @callback(cb)

        @show = (cb) =>

            pane = _.get(@state.pane_id)
            pane.classList.add('active')
            @state.active = true
            return @callback(cb)

        @hide = (cb) =>

            pane = _.get(@state.pane_id)
            pane.classList.remove('active')
            @state.active = false
            return @callback(cb)

        @step = (name='edit', cb) =>

            @hide()
            @timer = window.setTimeout(@show, 200)

            @state.step = name
            @template.t = @steps[name]
            return @render(cb)

        @edit = (e) =>

            if e? and e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            el = _.get(@state.element_id)
            _.unbind(el, 'dblclick')

            return @step 'edit', () =>
                el.classList.add('editing')
                el.contentEditable = true
                @state.cached_content = if @state.config.bundle is 'plain' then el.innerText else el.innerHTML

                document.body.addEventListener('dblclick', @save, true)
                el.focus()

        @save = (e) =>

            if e? and e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            pane = _.get(@state.pane_id)
            el = _.get(@state.element_id)
            el.contentEditable = false
            el.blur()
            el.classList.remove('editing')
            el.classList.add('saving')
            document.body.removeEventListener('dblclick', @save, true)

            html = if @state.config.bundle is 'plain' then el.innerText else el.innerHTML
            cached_html = @state.cached_content
            if html is cached_html
                return @hide () =>
                    el.classList.remove('saving')
                    _.bind(el, 'dblclick', @edit)
                    return @
            else
                return @step 'wait', () =>
                    return $.apptools.api.content.save_snippet(
                        keyname: @state.keyname
                        namespace: @state.namespace
                        html: html
                    ).fulfill
                        success: (response) =>
                            return @step 'done', () =>
                                el.innerHTML = response.html
                                _.bind(el, 'dblclick', @edit)

                                setTimeout(() =>
                                    @hide () =>
                                        el.classList.remove('saving')
                                , 1500)
                                return @

                        failure: (error) =>
                            el.classList.remove('saving')
                            return @step 'fail', () =>
                                setTimeout(@edit, 1500)
                                return @

        @init = () =>

            [@bundle, @commands] = @prep_bundle(_.indexOf(@state.bundles, @state.config.bundle))
            @commands.save = @save
            @steps = @constructor::steps
            @render()

            @state.init = true

            delete @init
            return @

        return @



@__apptools_preinit.abstract_base_classes.push Editor
@__apptools_preinit.abstract_base_classes.push EditorAPI
@__apptools_preinit.deferred_core_modules.push {module: EditorAPI, package: 'widgets'}
