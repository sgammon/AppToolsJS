
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


#### === Render Base Classes === ####

## Core
class TemplateLoader extends CoreObject
class RenderException extends CoreException

## Models
class Template extends Model

    constructor : () ->

        @name = ''
        @source = ''
        @cacheable =
            rendered: false     # should we cache rendered templates?
            source: false       # what about source?

        return @

class DOMTemplate extends Template

    constructor : (element) ->
        attrs = _.to_array(element.attributes)

        return

class TemplateContext extends Model
class RenderContext extends Model

    constructor: (ctxs=[]) ->

        for ctx in ctxs
            @[k] = v for own k, v of ctx

        return @


class RenderEnvironment extends Model

    @export = 'public'

    constructor: (options={}) ->
        ## Import logging
        @log = (message) => return console.log('[RenderEnvironment]', message)

        ## Setup initial state & extend with user options
        @state = _.extend(true, {},

            template_loaded: false     # is template ready to render?

            template: null             # default template to use
            context: null              # base context
            loader: null               # loader
            loader_priority: []        # order in which to load

            filters: {}                # environment filters (currently stubbed)
            globals: {}                # base globals (probably not needed in JS?)
            shared: false              # can environment be reused/shared?

        , options)

        ## Internal methods

        @resolve_loader = () =>
            # If no loader set, resolve appropriate source loader via loader priority list.
            @log('Resolving template loader...')

            priority = @state.loader_priority
            errors = []
            for driver in priority
                try
                    d = new driver()
                catch err
                    @log('Invalid driver:', driver.toString())
                finally
                    break if d?
                    continue

            if errors.length is priority.length
                throw new RenderException(@constructor.name, 'Unable to resolve valid template loader.')
            else
                @log('Template loader resolved.')
                return d

        @parse = () =>
            # parse Template and data object into pre-rendered Template
            @log('Template parsing currently stubbed.')

            return @

        ## External methods

        # Template loading
        @set_loader = (@loader) =>
            # Manually sets template loader for this environment.
            @log('Manually setting template loader.')

            return @

        @set_loader_priority = (p) =>
            # Manually sets priority array for template loaders
            @log('Manually assigning template loader priority.')

            @state.loader_priority = p if _.is_array(p)
            return @

        @load = (name, loader=@loader) =>
            # Loads a named template, defaults to current loader.

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
            @log('selfdestruct() currently stubbed. lucky you.');

            return @

        ## Init
        @_init = () =>
            if not @state.loader?
                try
                    @state.loader = @resolve_loader()
                catch err
                    console.error(@constructor.name, 'Couldn\'t resolve a template loader. Reraising...')
                    throw err

            return @

        return @

## Loaders
class StringLoader extends TemplateLoader
    # takes JS string template (Mustache {{x}} or Apptools [% x %] syntax) & returns prepared Template
    constructor: () ->

        @load = (pre_template) =>
            @constructor::log(@constructor.name, 'Loading string templates currently stubbed.')
            return pre_template

        return @

class DOMLoader extends TemplateLoader
    # takes pre-classed element and returns prepared Template
    constructor: () ->

        @load = (pre_template) =>
            @constructor::log(@constructor.name, 'Loading DOM templates currently stubbed.')
            return pre_template

        return @

class ModelLoader extends TemplateLoader
    # takes object model & returns prepped Template
    constructor: () ->

        @load = (pre_template) =>
            @constructor::log(@constructor.name, 'Loading model templates currently stubbed.')
            return pre_template

        return @

class StorageLoader extends TemplateLoader
    # takes StorageAPI key & returns stored Template
    constructor: () ->

        @load = (pre_template) =>
            @constructor::log(@constructor.name, 'Loading templates from storage currently stubbed.')
            return pre_template

        return @

class ServiceLoader extends TemplateLoader
    # takes StorageAPI key & returns stored Template
    constructor: () ->

        @load = (pre_template) =>
            @constructor::log(@constructor.name, 'Loading templates from the service layer is currently stubbed.')
            return pre_template

        return @


#### === Core Render API === ####
class CoreRenderAPI extends CoreAPI

    @mount = 'render'
    @events = []
    @export = 'private'

    constructor: (apptools, window) ->
        @_init = () =>
            @environment = new RenderEnvironment(shared: true).set_loader_priority([
                DOMLoader,
                StorageLoader,
                ModelLoader,
                StringLoader
            ])._init()
            @context = new RenderContext()


@__apptools_preinit.abstract_base_classes.push  QueryInterface,
                                                RenderInterface,
                                                AnimationInterface,
                                                TemplateLoader,
                                                RenderException,
                                                Template,
                                                DOMTemplate,
                                                TemplateContext,
                                                RenderContext,
                                                RenderEnvironment,
                                                StringLoader,
                                                DOMLoader,
                                                ModelLoader,
                                                StorageLoader,
                                                ServiceLoader,
                                                CoreRenderAPI

@__apptools_preinit.abstract_feature_interfaces.push QueryInterface,
                                                     RenderInterface,
                                                     AnimationInterface