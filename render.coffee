#### === Render/DOM Interfaces === ####
class QueryInterface extends Interface

    capability: 'query'
    required: ['element_by_id', 'elements_by_class', 'elements_by_tag', 'get']

    get: (selector) ->
    element_by_id: (id) ->
    elements_by_tag: (tagname) ->
    elements_by_class: (classname) ->

class RenderInterface extends Interface

    capability: 'render'
    required: []

    render: (template, context) ->

class AnimationInterface extends Interface

    capability: 'animation'
    required: ['animate']

    animate: (to, settings) ->


# Render API
class CoreRenderAPI extends CoreAPI

    @mount = 'render'
    @events = []
    @export = 'private'

    constructor: (apptools, window) ->
        @environment = new RenderEnvironment(
            shared: true
            context: new RenderContext()
        ).set_loader_priority([
            StringLoader,
            ModelLoader,
            DOMLoader,
            StorageLoader,
        ])._init()


class TemplateLoader extends CoreObject
class RenderException extends CoreException

class Template

    @export = 'public'

    constructor : (@source) ->

        @name = ''
        @cacheable =
            rendered: false     # should we cache rendered templates?
            source: false       # what about source?

        return @

class DOMTemplate extends Template

    constructor : (element) ->
        attrs = _.to_array(element.attributes)


class StringLoader extends TemplateLoader
    # takes JS string template ({{etc}}) & returns prepared Template
    constructor: () ->

        @engine = new t('')

        @load = (template) =>
            @engine.template(template)
            return @

        return @

class DOMLoader extends TemplateLoader
    # takes pre-classed element and returns prepared Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading DOM templates currently stubbed.')
            return pre_template

        return @

class ModelLoader extends TemplateLoader
    # takes object model & returns prepped Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading model templates currently stubbed.')
            return pre_template

        return @

class StorageLoader extends TemplateLoader
    # takes StorageAPI key & returns stored Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading templates from storage currently stubbed.')
            return pre_template

        return @

class ServiceLoader extends TemplateLoader
    # takes remote template path & returns via service layer call
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading templates from a remote service is currently stubbed.')
            return pre_template

        return @

class RenderContext

    constructor: (ctxs=[]) ->

        for ctx in ctxs
            _.extend(@, ctx)

        @add = (context) =>
            _.extend(@, context)
            return @

        return @

class RenderEnvironment

    @export = 'public'

    constructor: (options={}) ->
        ## Setup initial state & extend with user options

        @state = _.extend(true, {},

            template_loaded: false     # is template ready to render?

            template: null             # default template to use
            context: false             # base context
            loader: false              # loader
            loader_priority: []        # order in which to load

            filters: {}                # environment filters (currently stubbed)
            globals: {}                # base globals (probably not needed in JS?)
            shared: false              # can environment be reused/shared?

        , options)

        ## Internal methods

        @resolve_loader = () =>
            # If no loader set, resolve appropriate source loader via loader priority list.
            console.log('[Render] Resolving template loader...')

            priority = @state.loader_priority
            errors = []
            for driver in priority
                try
                    d = new driver()
                catch err
                    console.log('[Render] Invalid driver:', driver.toString())
                finally
                    break if d?
                    continue

            if errors.length is priority.length
                throw new RenderException(@constructor.name, 'Unable to resolve valid template loader.')
            else
                console.log('[Render] Template loader resolved.')
                return d

        @parse = () =>
            # parse Template and data object into pre-rendered Template
            console.log('Template parsing currently stubbed.')

            return @

        ## External methods

        # Template loading
        @set_loader = (@loader) =>
            # Manually sets template loader for this environment.
            console.log('Manually setting template loader.')

            return @

        @set_loader_priority = (p) =>
            # Manually sets priority array for template loaders
            console.log('Manually assigning template loader priority.')

            @state.loader_priority = p if _.is_array(p)
            return @

        @load = (name) =>
            # Loads a named template

            if _.is_array(name)
                return @select(name, loader)
            else
                return @

        @select = (names, loader=@loader) =>
            # Returns first found template in list of template names

            if !_.is_array(names)
                return @load(names, loader)
            else
                return @

        # Single-use manual loaders
        @load[k] = v for k, v of {
            from_string: (string) =>
                # Manually load template from string parameter.
                return @

            from_element: (element) =>
                # Manually load template from DOM element.
                return @

            from_model: (model) =>
                # Manually load template from model.
                return @
        }

        ## API methods
        @selfdestruct = () =>
            # Perform any final cleanup & trigger self-delete with Render API
            console.log('selfdestruct() currently stubbed. lucky you.');

            return @

        ## Init
        @_init = () =>
            if not @loader?
                try
                    @loader = @resolve_loader()
                    @state.loader = true
                catch err
                    console.error(@constructor.name, 'Couldn\'t resolve a template loader. Reraising...')
                    throw err

            return delete @_init

        return @


@__apptools_preinit.abstract_base_classes.push  QueryInterface,
                                                RenderInterface,
                                                AnimationInterface,
                                                RenderException,
                                                Template,
                                                DOMTemplate,
                                                TemplateLoader,
                                                RenderContext,
                                                RenderEnvironment,
                                                StringLoader,
                                                DOMLoader,
                                                ModelLoader,
                                                StorageLoader,
                                                ServiceLoader,
                                                CoreRenderAPI

@__apptools_preinit.abstract_feature_interfaces.push DOMInterface,
                                                     QueryInterface,
                                                     RenderInterface,
                                                     AnimationInterface
